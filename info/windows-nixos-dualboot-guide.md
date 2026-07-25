# Windows 10 na NixOS — kompletny przewodnik (B550 + Ryzen 5 3600)

> Notatka ze wszystkimi problemami i rozwiązaniami podczas instalacji Windows 10 Home x64 PL obok NixOS na platformie AMD B550 + Ryzen 5 3600.

---

## 1. Tworzenie bootowalnego pendrive'a z ISO na NixOS

BalenaEtcher (AppImage) nie działa na NixOS. Użyj wbudowanego `dd`:

```bash
sudo dd if=/sciezka/do/win10.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

**Ważne:** `of=/dev/sdX` (cały dysk), **nie** `/dev/sdX1` (partycja). Sprawdź `lsblk` przed.

Alternatywy:
- `woeusb` — dla Windows ISO
- `ventoy` — bootuje wiele ISO z jednego pendrive'a
- `popsicle` / `usbimager` — GUI

---

## 2. Instalator Windows nie widzi dysków (RAID vs AHCI)

### Problem
Na płytach AMD B550 z Ryzen 3000/5000 BIOS często domyślnie ustawia **RAID** (AMD RAIDXpert2). Windows PE nie ma wbudowanych sterowników AMD RAID, więc instalator nie widzi dysków.

### Rozwiązanie — nie przełączaj na AHCI!
Przełączenie na AHCI na B550 z Ryzen 3000 często psuje bootowanie NixOS/GRUBa. Zostaw RAID w BIOS i załaduj sterownik w instalatorze.

### Pobierz właściwy sterownik
- **AMD RAID Driver (SATA, NVMe RAID)** — plik **2.8 MB** (to F6 driver)
- **NIE** pobieraj RAIDXpert2 (200 MB) — to jest do zarządzania RAID z poziomu Windows, nie do instalacji
- Link: [AMD Support](https://www.amd.com/en/support)

Rozpakuj ZIP na pendrive FAT32 (np. w folder `AMD-RAID/`).

### Załaduj sterownik w instalatorze Windows
1. Na ekranie "Where do you want to install Windows?" kliknij **Load driver** (Załaduj sterownik)
2. **Odznacz** checkbox: `Ukryj sterowniki niezgodne ze sprzętem...` — instalator ukrywa wszystko, bo "nie widzi" dysku
3. Przejdź do folderu z rozpakowanym driverem → `WIN10/x64/`
4. W zależności od dysku wybierz:
   - **M.2 NVMe** → `NVMe_CC` (rozwiń strzałkę, wybierz folder z plikami `.inf`)
   - **M.2 SATA / SATA SSD** → `RAID_SATA/rcraid` (lub załaduj po kolei: `rcbottom` → `rccfg` → `rcraid`)
5. Kliknij **OK** → dyski się pojawią

---

## 3. Partycjonowanie — zostaw miejsce na NixOS

Jeśli na SSD już jest NixOS:
1. W instalatorze Windows usuń **tylko** partycje, które chcesz przeznaczyć pod Windows
2. **NIE ruszaj** partycji EFI (512 MB), jeśli tam stoi GRUB NixOS
3. Utwórz nową partycję NTFS dla Windows (~50% wolnego miejsca)
4. Resztę zostaw **nieprzydzieloną** — tam później zainstalujesz NixOS lub rozszerzysz obecny

**Uwaga:** Windows instalator agresywnie nadpisuje EFI. Jeśli NixOS już stoi na tym dysku, po instalacji Windows trzeba będzie przywrócić GRUBa z ISO NixOS:
```bash
sudo mount /dev/nvme0n1pX /mnt          # root NixOS
sudo mount /dev/nvme0n1pY /mnt/boot/efi # EFI partition
sudo nixos-enter
nixos-rebuild switch --install-bootloader
```

---

## 4. autounattend.xml — konfiguracja dla gier (schneegans.de)

Generator: [schneegans.de/windows-unattend](https://schneegans.de/windows-unattend/)

### Kluczowe ustawienia dla gier + dual-boot:

| Sekcja | Ustawienie |
|--------|-----------|
| **Język** | Polish, Polish (Programmers), Poland |
| **Klucz** | Use product key stored in BIOS/UEFI firmware |
| **Architektura** | amd64 (x64) |
| **Windows PE** | Run interactively (sam wybierzesz partycje) |
| **Partition layout** | GPT (UEFI) |
| **Computer name** | np. DESKTOP-GAMING |
| **Time zone** | Central European Standard Time |
| **User accounts** | Lokalne konto, Administrators, Passwords do not expire |
| **Fast Startup** | **Disable** — obowiązkowo dla dual-boot! |
| **System Protection** | Disable (oszczędza miejsce na SSD) |
| **Core isolation** | **Keep enabled** — potrzebne do gier wymagających HV |
| **Prevent device encryption** | Nie zaznaczaj (to BitLocker, nie HV) |
| **Visual effects** | Adjust for best performance |
| **Disable Edge Startup Boost** | Tak |
| **Disable Enhance Pointer Precision** | Tak (FPS) |
| **Express settings** | Disable all (privacy) |
| **Bloatware** | Usuń wszystko oprócz Microsoft Store (jeśli Game Pass) |

### Po instalacji Windows (obowiązkowo!):
1. Wyłącz **Fast Startup**: Panel sterowania → Opcje zasilania → Wybierz działanie przycisku zasilania → odznacz "Włącz szybkie uruchamianie"
2. Włącz wymagane funkcje dla gier HV: Panel sterowania → Programy i funkcje → Włącz lub wyłącz funkcje Windows → zaznacz **Platforma maszyny wirtualnej** i **Platforma hypervisora Windows**
3. W BIOS: VT-x / AMD-V → Enabled, IOMMU → Enabled

---

## 5. Montowanie partycji Windows (NTFS) z NixOS

### Problem 1: `mount: wrong fs type, bad option, bad superblock`
NixOS domyślnie nie ma `ntfs3g` w PATH, a kernelowy `ntfs` nie wspiera zapisu z opcjami `ntfs-3g`.

### Problem 2: `sudo: ntfs3g: command not found`
`nix-shell` zmienia PATH tylko dla użytkownika. `sudo` ma własny PATH i nie widzi binarek z nix-shella.

### Problem 3: `fsconfig() failed: ntfs: Unknown parameter 'remove_hiberfile'`
Kernelowy `mount -t ntfs` nie rozumie opcji `remove_hiberfile`. Ta opcja działa tylko z userspace `ntfs-3g`.

### Rozwiązanie — poprawne zamontowanie NTFS do zapisu:

```bash
# 1. Wejdź w nix-shell z ntfs3g
nix-shell -p ntfs3g

# 2. Zamontuj z zachowaniem PATH dla sudo (kluczowe!)
sudo env "PATH=$PATH" ntfs-3g -o remove_hiberfile /dev/sda2 /mnt/win

# Alternatywnie:
sudo $(command -v ntfs-3g) -o remove_hiberfile /dev/sda2 /mnt/win

# 3. Sprawdź czy działa
mount | grep /mnt/win
ls /mnt/win

# 4. Wrzuć pliki
sudo cp -r ~/Gry /mnt/win/
sudo umount /mnt/win
```

**Uwaga:** `remove_hiberfile` usuwa plik hibernacji Windows (Fast Startup). Windows straci otwarte programy/zakładki z ostatniej sesji. Po skopiowaniu plików — **wyłącz Fast Startup w Windows na stałe**, żeby nie musieć tego robić za każdym razem.

### Tylko do odczytu (bezpieczniejsze):
```bash
sudo mount -t ntfs -o ro /dev/sda2 /mnt/win
```

---

## 6. Dual-boot — NixOS + Windows

### W NixOS `configuration.nix`:
```nix
boot.loader.grub = {
  enable = true;
  efiSupport = true;
  device = "nodev";
  useOSProber = true;  # automatycznie znajdzie Windows
};
boot.loader.efi.canTouchEfiVariables = true;
```

### Po zmianie partycji (resize, nowy Windows):
Jeśli UUID się zmienił, zregeneruj konfigurację:
```bash
sudo nixos-generate-config --root /mnt
# i ręcznie przenieś blok fileSystems do swojego hardware-configuration.nix
```

---

## 7. Szybka ściąga — komendy

```bash
# Pendrive z ISO (dd)
sudo dd if=win10.iso of=/dev/sdX bs=4M status=progress conv=fsync

# Montowanie NTFS do zapisu
nix-shell -p ntfs3g
sudo env "PATH=$PATH" ntfs-3g -o remove_hiberfile /dev/sda2 /mnt/win

# Przywracanie GRUBa po Windows
sudo mount /dev/nvme0n1pX /mnt
sudo mount /dev/nvme0n1pY /mnt/boot/efi
sudo nixos-enter
nixos-rebuild switch --install-bootloader

# Sprawdź filesystemy i UUID
lsblk -f

# Sprawdź co jest zamontowane
mount | grep /mnt/win
```

---

## Podsumowanie problemów i rozwiązań

| Problem | Przyczyna | Rozwiązanie |
|---------|-----------|-------------|
| Etcher nie działa | AppImage na NixOS brakuje bibliotek | Użyj `dd`, `woeusb` lub `ventoy` |
| Instalator nie widzi dysku | RAID w BIOS, brak sterownika | Załaduj AMD RAID driver (2.8 MB, nie 200 MB) |
| "Nie znaleziono podpisanych sterowników" | Zaznaczony checkbox "Ukryj niezgodne" | Odznacz checkbox w Load driver |
| rcraid załadowany, dysków nadal nie ma | M.2 NVMe zamiast SATA | Wybierz `NVMe_CC` zamiast `RAID_SATA` |
| `ntfs3g: command not found` | sudo nie widzi PATH z nix-shell | `sudo env "PATH=$PATH" ntfs-3g ...` |
| `Unknown parameter 'remove_hiberfile'` | Kernelowy ntfs ≠ ntfs-3g | Użyj `ntfs-3g` (userspace), nie `mount -t ntfs` |
| Windows 100% dysku po instalacji | SysMain, indeksowanie, aktualizacje | Wyłącz SysMain, WSearch, poczekaj na aktualizacje |
| Linux nie bootuje po zmianie AHCI/RAID | BIOS gubi ścieżkę GRUBa na B550 | Zostaw RAID, załaduj driver w Windows |




nix-shell -p woeusb

[nix-shell:~]$ sudo woeusb --device /home/shin/Downloads/Win10_22H2_Polish_x64v1.iso /dev/sdb
or
[nix-shell:~]$ sudo woeusb --device /home/shin/Downloads/Win10_22H2_Polish_x64v1.iso /dev/sdb1
---

*Wygenerowano: 2026-07-14*
