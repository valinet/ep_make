# ep_make

`ep_make` is a script which builds and installs ExplorerPatcher on your computer.

To run the latest version, open Run (press `Win`+`R` on your keyboard) and type the following:

```
powershell iex (irm 'https://raw.githubusercontent.com/valinet/ep_make/master/ep_make.ps1')
```

A console window will pop up - progress will be displayed there. When everything finishes, a prompt will show on the screen for running `ep_setup.exe` which will then install the locally-built ExplorerPatcher on the system. `explorer.exe` will restart and ExplorerPatcher will then get loaded. The generated binaries are fully compatible with the update system in ExplorerPatcher - if you chose so, you will get notified about new versions as usual. You have the option to set ExplorerPatcher to use `ep_make` when updating instead of the pre-compiled bianries from GitHub - check the *Update* section in *ExplorerPatcher Properties* for more info.

## Key points

* It has no external dependencies: files required for building, like the Microsoft Visual C/C++ compiler, the Windows SDK, cmake, git etc are downloaded in a portable manner on the computer. But don't worry, it also works on PCs set up for development.
* It doesn't require any "exotic" features like virtualization support, containers, WSL etc, since it is designed to run even on Home editions of Windows, so that it helps users no matter what Windows version they are running.
* The script not install any programs and it does not alter the registry; in fact, it is designed to compile succesfully when run *without* administrative priviledges. The recommended way is to run *without* administrative priviledges.
* It is oficially sanctioned to be used alongside ExplorerPatcher: for example, it can be invoked by the built-in updater if you want to use a locally generated build of the latest version (check the *Update* section in *ExplorerPatcher Properties*).
* It also acts as official guidance on how to build ExplorerPatcher, alongside the [wiki page](https://github.com/valinet/ExplorerPatcher/wiki/Compiling) and the GitHub Actions [workflow specification](https://github.com/valinet/ExplorerPatcher/blob/master/.github/workflows/build.yml).
* One of the goals is to reduce antivirus false positives and avoid disturbance for ExplorerPatcher users; due to the nature of ExplorerPatcher, it is often flagged as malicious by antivirus vendors, and lately it doesn't happen immediatly after a release is pushed, but only after it gains some popularity. We recognize this brings a whole deal of inconvinience to our users: from broken installs to upfront inability to upgrade to the newer version due to corporate policy. By building the software from source locally, a unique binary is generated, which is functionally the same as the "official" release but should prevent detection by antivirus engines based on hashes alone, the most widespread method through which we get flagged.
* Building software locally is not associated with casual computer use, with the blame being put on users who "do not want to bother with that", when in fact it is all about the overly complicated steps involving the process. But that shouldn't be the case: the build process itself should not be a deterant; thus, we aim to make it as easily as possible for everyone to get started with a script that just works when run.
* Pre-compiled binaries will still be offered; this will just be an alternative method for maintaining your ExplorerPatcher installation, available for users to choose from.

## Requirements

* Internet connection
* Up to 5 GB of free space on the `C:\` drive

## Options

The command line interface will be improved based on community and user feedback.

| Command | Description |
| ----------- | ----------- |
| `-Commit`| `string, defaults to "default"` Specifies which commit to checkout when building ExplorerPatcher. Specifying `default` will employ the same behavior as the ExplorerPatcher updater: the registry is checked for your update preference (release/pre-release), and then the information about the latest release is grabbed from the update server. |
