# Inheritance follows `enable`

Home Manager agent modules write no files while `enable = false`. This flake does the same: catalogs attach only when `programs.<name>.enable = true`. Want the files without the binary → `enable = true; package = null`.
