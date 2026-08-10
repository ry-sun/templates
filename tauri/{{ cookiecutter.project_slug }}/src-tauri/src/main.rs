#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    {{ cookiecutter.__crate_name }}_lib::run();
}
