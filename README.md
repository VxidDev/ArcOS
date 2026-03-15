# ArcOS

**ArcOS** is a lightweight command-line operating system written in x86 assembly.
The project focuses on learning low-level programming, bootloader development, and operating system fundamentals.

---

## Features (Planned / In Progress)

* Interactive command-line shell
* Basic command parsing
* Screen and keyboard interaction through BIOS
* Simple filesystem support

---

## Project Status

* [x] Bootloader
* [ ] Basic shell functionality *(in progress)*
* [ ] Filesystem

---

## Goals

ArcOS aims to explore and demonstrate:

* Low-level **x86 assembly programming**
* **Boot sector development**
* **BIOS interrupt usage**
* **Minimal operating system design**

The long-term goal is to evolve ArcOS from a simple bootable shell into a small but functional operating system.

---

## Building

ArcOS is built using **NASM** and runs on an x86 emulator such as **QEMU**.

Example build process:

```
make
make run
```

---

