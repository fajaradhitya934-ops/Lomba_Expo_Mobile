alat untuk firebase ("curl -sL https://firebase.tools | bash")
firebase login, login di crome
kelik di terminal untuk mencari path nya (export PATH="$PATH":"$HOME/.pub-cache/bin")
flutterfire configure(pilih prestasi-51e6f) 

--
membuat project fluttter ("flutter create --project-name brainhub_ui .")



daftar file 
home_screen ( profil)
projects_screen (halaman upload project apa yang di up)
add_project_screen(hakamann menambahkan project)


 flutter run -d chrome --web-port=5000


51:CA:A2:9C:26:F7:8B:6B:2A:31:F4:A5:89:39:BE:90:29:2C:19:6F


buat aktivasi python
source venv/bin/activate
python3 app.py
run-emu untuk menjalankan emulator android


adb connect 192.168.1.5:5555 (isi dengan port hp dan wifi)
adb pair 192.168.110.12:44475

adb kill-server
adb start-server


Pastikan drive OS mounted writable

Cek:

mount | grep nvme0n1p3
Kalau muncul:

(ro,...)

berarti NTFS masuk read-only lagi.

Fix:

    sudo umount /media/fajaradhitya/OS
    sudo ntfsfix /dev/nvme0n1p3
sudo mount -o rw /dev/nvme0n1p3 /media/fajaradhitya/OS

Jalankan emulator TANPA snapshot

Karena snapshot di NTFS rawan corrupt.

Selalu pakai:

emulator -avd Android_Fresh -gpu swiftshader_indirect -no-snapshot

Dan untuk storage

Sesekali bersihin:

rm -rf ~/.gradle/caches
rm -rf ~/.cache/*