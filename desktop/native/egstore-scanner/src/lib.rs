#![deny(clippy::all)]

#[cfg(not(windows))]
compile_error!("egdata-native-scanner is Windows-only");

use std::collections::HashMap;
use std::ffi::OsString;
use std::os::windows::ffi::{OsStrExt, OsStringExt};
use std::path::{Path, PathBuf};
use std::ptr;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, MutexGuard, OnceLock};

use napi::bindgen_prelude::AsyncTask;
use napi::{Env, Error, Result, Status, Task};
use napi_derive::napi;
use windows_sys::Win32::Foundation::INVALID_HANDLE_VALUE;
use windows_sys::Win32::Storage::FileSystem::{
    FindClose, FindExInfoBasic, FindExSearchNameMatch, FindFirstFileExW, FindNextFileW,
    GetFileAttributesW, FILE_ATTRIBUTE_DIRECTORY, FILE_ATTRIBUTE_REPARSE_POINT,
    FIND_FIRST_EX_LARGE_FETCH, INVALID_FILE_ATTRIBUTES, WIN32_FIND_DATAW,
};

static ACTIVE_SCANS: OnceLock<Mutex<HashMap<String, Arc<AtomicBool>>>> = OnceLock::new();

#[napi(object)]
pub struct ScanResult {
    pub egstores: Vec<String>,
    pub directories_checked: u32,
}

pub struct ScanOutput {
    egstores: Vec<String>,
    directories_checked: u32,
}

pub struct ScanTask {
    root: PathBuf,
    operation_id: String,
    cancelled: Arc<AtomicBool>,
    max_depth: Option<u32>,
}

impl Task for ScanTask {
    type Output = ScanOutput;
    type JsValue = ScanResult;

    fn compute(&mut self) -> Result<Self::Output> {
        scan_drive(&self.root, &self.cancelled, self.max_depth)
    }

    fn resolve(&mut self, _env: Env, output: Self::Output) -> Result<Self::JsValue> {
        Ok(ScanResult {
            egstores: output.egstores,
            directories_checked: output.directories_checked,
        })
    }

    fn finally(self, _env: Env) -> Result<()> {
        lock_active_scans().remove(&self.operation_id);
        Ok(())
    }
}

#[napi]
pub fn scan(
    root: String,
    operation_id: String,
    max_depth: Option<u32>,
) -> Result<AsyncTask<ScanTask>> {
    let root = PathBuf::from(root);
    if !root.is_absolute() || operation_id.is_empty() || max_depth.is_some_and(|depth| depth > 64) {
        return Err(Error::new(
            Status::InvalidArg,
            "The native scan request is invalid.",
        ));
    }

    let cancelled = Arc::new(AtomicBool::new(false));
    let mut scans = lock_active_scans();
    if scans.contains_key(&operation_id) {
        return Err(Error::new(
            Status::InvalidArg,
            "The native scan operation already exists.",
        ));
    }
    scans.insert(operation_id.clone(), Arc::clone(&cancelled));
    drop(scans);

    Ok(AsyncTask::new(ScanTask {
        root,
        operation_id,
        cancelled,
        max_depth,
    }))
}

#[napi]
pub fn cancel(operation_id: String) -> bool {
    let scans = lock_active_scans();
    let Some(cancelled) = scans.get(&operation_id) else {
        return false;
    };
    cancelled.store(true, Ordering::Release);
    true
}

fn lock_active_scans() -> MutexGuard<'static, HashMap<String, Arc<AtomicBool>>> {
    ACTIVE_SCANS
        .get_or_init(|| Mutex::new(HashMap::new()))
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
}

fn scan_drive(root: &Path, cancelled: &AtomicBool, max_depth: Option<u32>) -> Result<ScanOutput> {
    let native_root = extended_path(root);
    let root_attributes = get_attributes(&native_root);
    if root_attributes == INVALID_FILE_ATTRIBUTES
        || root_attributes & FILE_ATTRIBUTE_DIRECTORY == 0
        || root_attributes & FILE_ATTRIBUTE_REPARSE_POINT != 0
    {
        return Err(Error::new(
            Status::GenericFailure,
            "The native scanner could not access the drive root.",
        ));
    }

    let mut pending = vec![(native_root, 0_u32)];
    let mut egstores = Vec::new();
    let mut directories_checked = 0_u32;

    while let Some((directory, depth)) = pending.pop() {
        check_cancelled(cancelled)?;
        directories_checked = directories_checked.saturating_add(1);

        let pattern = directory.join("*");
        for_each_match(&pattern, |entry| {
            if cancelled.load(Ordering::Acquire) {
                return false;
            }
            if entry.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY == 0
                || entry.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT != 0
            {
                return true;
            }

            let name = find_name(entry);
            if name == "." || name == ".." || should_skip(&name) {
                return true;
            }

            let child = directory.join(&name);
            if name.eq_ignore_ascii_case(".egstore") {
                if contains_manifest(&child, cancelled) {
                    egstores.push(display_path(&child));
                }
            } else if max_depth.is_none_or(|limit| depth < limit) {
                pending.push((child, depth.saturating_add(1)));
            }
            true
        });
    }

    check_cancelled(cancelled)?;
    Ok(ScanOutput {
        egstores,
        directories_checked,
    })
}

fn contains_manifest(directory: &Path, cancelled: &AtomicBool) -> bool {
    let pattern = directory.join("*.manifest");
    let mut found = false;
    for_each_match(&pattern, |entry| {
        if cancelled.load(Ordering::Acquire) {
            return false;
        }
        let name = find_name(entry);
        if entry.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY == 0
            && name
                .to_string_lossy()
                .to_ascii_lowercase()
                .ends_with(".manifest")
        {
            found = true;
            return false;
        }
        true
    });
    found
}

fn for_each_match(pattern: &Path, mut visit: impl FnMut(&WIN32_FIND_DATAW) -> bool) {
    let encoded = wide_null(pattern);
    let mut data = WIN32_FIND_DATAW::default();
    let handle = unsafe {
        FindFirstFileExW(
            encoded.as_ptr(),
            FindExInfoBasic,
            (&mut data as *mut WIN32_FIND_DATAW).cast(),
            FindExSearchNameMatch,
            ptr::null(),
            FIND_FIRST_EX_LARGE_FETCH,
        )
    };
    if handle == INVALID_HANDLE_VALUE {
        return;
    }

    loop {
        if !visit(&data) {
            break;
        }
        if unsafe { FindNextFileW(handle, &mut data) } == 0 {
            break;
        }
    }
    unsafe {
        FindClose(handle);
    }
}

fn get_attributes(path: &Path) -> u32 {
    let encoded = wide_null(path);
    unsafe { GetFileAttributesW(encoded.as_ptr()) }
}

fn find_name(data: &WIN32_FIND_DATAW) -> OsString {
    let length = data
        .cFileName
        .iter()
        .position(|character| *character == 0)
        .unwrap_or(data.cFileName.len());
    OsString::from_wide(&data.cFileName[..length])
}

fn should_skip(name: &OsString) -> bool {
    let name = name.to_string_lossy();
    [
        "$Recycle.Bin",
        "System Volume Information",
        "Windows",
        "Recovery",
        "MSOCache",
    ]
    .iter()
    .any(|candidate| name.eq_ignore_ascii_case(candidate))
}

fn extended_path(path: &Path) -> PathBuf {
    let value = path.as_os_str().to_string_lossy();
    if value.starts_with(r"\\?\") {
        return path.to_path_buf();
    }
    if let Some(unc) = value.strip_prefix(r"\\") {
        return PathBuf::from(format!(r"\\?\UNC\{unc}"));
    }
    PathBuf::from(format!(r"\\?\{value}"))
}

fn display_path(path: &Path) -> String {
    let value = path.as_os_str().to_string_lossy();
    if let Some(unc) = value.strip_prefix(r"\\?\UNC\") {
        return format!(r"\\{unc}");
    }
    value.strip_prefix(r"\\?\").unwrap_or(&value).to_string()
}

fn wide_null(path: &Path) -> Vec<u16> {
    path.as_os_str().encode_wide().chain(Some(0)).collect()
}

fn check_cancelled(cancelled: &AtomicBool) -> Result<()> {
    if cancelled.load(Ordering::Acquire) {
        return Err(Error::new(Status::Cancelled, "SCAN_CANCELLED"));
    }
    Ok(())
}
