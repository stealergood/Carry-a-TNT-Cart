# Carry a TNT Cart

Source Luau proyek ini disinkronkan ke Roblox Studio dengan [Rojo](https://rojo.space/docs). Model `Workspace.Minecart_Default_TNT` ada di place Studio; salinan place dengan model yang sudah disiapkan tersedia sebagai `Carry a TNT Cart - Carry System.rbxl`.

## Sistem carry

- Tekan `E` pada `ProximityPrompt` untuk mengambil tali. Satu pemain hanya dapat menarik satu cart dan satu cart hanya memiliki satu penarik.
- Berjalan menjauh hingga melewati `RopeSlackLength` untuk menarik cart. Tali memakai batas fisik `RopeConstraint` sekaligus spring-damper, sehingga pemain tidak dapat menjauh melebihi `RopeMaxLength`. Tali terkunci selama cart valid; hanya dilepas otomatis saat pemain mati, respawn, keluar, atau cart invalid.
- Pemain dapat mendorong cart secara fisik tanpa mengambil tali. Tarikan atau dorongan diagonal akan membelokkan cart ke arah gaya, sementara lateral grip mengurangi efek selip seperti kardus.
- Empat roda visual berputar lokal berdasarkan kecepatan dan arah cart; collider roda tetap memakai proxy sederhana agar physics stabil.
- Cart mengikuti kemiringan permukaan di bawah roda. Saat ditarik atau didorong, bantuan tanah mengimbangi gravitasi di tanjakan dan membantu melewati bibir rendah; bantuan mati ketika roda tidak lagi dekat dengan tanah. Tarikan mundur mempertahankan arah poros cart agar tidak memaksa putar balik di jalur sempit.
- Cart memiliki 100 HP. Bar HP kecil tanpa teks angka di atas cart tersembunyi saat penuh, lalu tampil setelah menerima damage dari `Workspace.part_dmg`.
- Saat HP mencapai 0, cart meledak, membunuh pemain dalam radius, dan pecah menjadi fragmen fisik yang dibersihkan otomatis. Cart baru lalu respawn di titik awalnya dengan kondisi penuh.
- Server mengatur klaim, cleanup, massa, hard speed limit, dan pemeriksaan teleport. Modul `CartMotion` menghitung semua gaya: server menjalankannya saat cart idle, client pemilik saat cart ditarik. Saat idle, server memegang physics ownership agar dorongan dan gaya yang dihitung server tetap konsisten.

## Party lobby

- Delapan area di `Workspace.PartyDesign` memakai `PartyBounds01` sebagai sensor. Pemain pertama menjadi host, dipindahkan ke tengah, dan membuka `StarterGui.PartyGui`.
- Host memilih kapasitas 1–4 (default 2), mengaktifkan Friends Only bila perlu, lalu menekan Create Party. Server memeriksa pertemanan dengan host; pemain tidak dapat menjadi anggota dua party sekaligus.
- Billboard tersembunyi saat area kosong atau host mengatur party. Setelah Create, billboard hanya menampilkan teks countdown dan jumlah aktual/kapasitas, misalnya `15s` dan `1/4`. Tidak ada panel atau label rentang pemain.
- Countdown berlangsung 15 detik, termasuk jika party penuh. Tombol Leave keluar dari antrean; host keluar membubarkan antrean. Konfigurasi tanpa konfirmasi dibatalkan setelah 60 detik.
- Setelah countdown, server memilih titik kosong acak di `LobbyEnvirontment.PartySpawn`, membuat satu cart, lalu memasang anggota otomatis di depan, belakang, kanan, kiri sesuai urutan masuk. Cart party memakai physics ownership server; cart manual tetap memakai sistem satu penarik.
- Cart atau anggota yang mencapai checkpoint berikutnya menyimpan checkpoint seluruh party. Kematian/ledakan mengulang seluruh party setelah jeda respawn; sebelum checkpoint pertama dipilih PartySpawn acak kembali.
- Anggota disconnect saat permainan berjalan, peluncuran, atau respawn membubarkan permainan. Server membatalkan sesi, menghapus cart/tali/efek, mengembalikan anggota tersisa ke `LobbyEnvirontment.SpawnArea.LobbySpawn`, dan menampilkan notifikasi siapa yang keluar. Karakter yang belum hidup dikembalikan setelah respawn.
- GUI, billboard, barrier, marker area, dan template cart berada langsung di Studio. Rojo hanya menyinkronkan script. `tools/studio/SetupPartyScene.luau` adalah sumber setup satu kali, bukan script runtime; jangan dijalankan ulang di scene yang sudah disiapkan.
- Tekstur studs tersimpan di `assets/party-ui/Studs.png`, Roblox image `104291473736518`; referensi Figma tersimpan pada atribut `PartyGui.DesignSource`.

Validasi implementasi dibatasi pada pemeriksaan source, format, build Rojo, dan inspeksi objek Edit. **Jangan menjalankan playtest tanpa permintaan eksplisit pengguna.** Perilaku multiplayer dan rasa tarikan empat pemain belum diverifikasi melalui permainan.

## Menambah cart

Duplikasi `Minecart_Default_TNT` yang sudah disiapkan, tempatkan di `Workspace`, dan pertahankan tag `CarryCart`. Server akan mendaftarkan clone, membuat `CartId` baru jika duplikat, dan menyiapkan komponen physics yang belum ada. Jangan ubah nama `PhysicsRoot`, `PullAttachment`, dan `CarryPrompt` kecuali juga mengubah `src/shared/CartConstants.luau`.

## Penyesuaian dan validasi

- `RopeSlackLength` menentukan jarak bebas sebelum tarikan aktif, sedangkan `RopeMaxLength` adalah batas fisik jarak pemain-cart. `PullSpringAccelerationPerStud`, `PullDampingAcceleration`, dan `MaxPullAcceleration` mengatur rasa tali. `SoftSpeedStart` membuat tenaga memudar sebelum `MaxCartSpeed`; `SpeedBrakeAcceleration` mengerem kecepatan berlebih secara halus. Batas `HardMaxCartSpeed` hanya pengaman server.
- Semua sumber damage memakai CollectionService tag `CartDamage`, termasuk `Workspace.part_dmg` yang lama. Tag dapat dipasang langsung pada BasePart atau pada Model yang membungkus beberapa part; model yang ditag dihitung sebagai satu sumber damage. Untuk menambahkan obstacle baru, pilih BasePart atau Model tersebut di Studio lalu tambahkan tag `CartDamage`; nama tidak berpengaruh. `CartMaxHealth`, `DamagePerHit`, dan `DamageProxySize` mengatur sistem HP serta cakupan hitbox. Damage hanya terjadi saat mulai menyentuh obstacle; cart harus keluar lalu menyentuh kembali untuk menerima damage berikutnya. `DamageExitGrace` menyaring getaran kontak physics agar tidak menghasilkan double damage.
- `ExplosionRadius`, `ExplosionMaxFragments`, kecepatan fragmen, dan `ExplosionFragmentLifetime` mengatur dampak serta biaya performa ledakan.
- `CartRespawnDelay` mengatur jeda sebelum cart yang meledak muncul kembali di titik spawn awal.
- `TargetCartMass` mengatur massa fisik pada ballast rendah. Gaya tarik, dorong, dan resistance mengikuti massa assembly. `CartFriction` sengaja rendah karena wheel proxy di-weld dan tidak berputar. `RollingResistance` dan `VelocityResistance` berlaku untuk tarikan tali; `IdlePushRollingResistance` serta `IdlePushVelocityResistance` khusus memperberat cart saat didorong tanpa tali. Karakter tidak memberi impuls physics langsung pada cart; `PushProxy` mendeteksi karakter dan menerapkan gaya dorong server yang dibatasi melalui `PushSpringAccelerationPerSpeed`, `PushDampingAcceleration`, dan `MaxPushAcceleration`.
- `PullerMaxSpeedPenalty` dan `MinPullerWalkSpeed` mengatur seberapa besar beban memengaruhi pemain. `UprightSpringTorque` serta `UprightDampingTorque` menahan roll/pitch tanpa mengunci arah yaw cart.
- `GroundMaxSlopeAngle` membatasi bantuan tanjakan (30 derajat); `GroundContactGrace` menentukan jarak kontak roda. `StepMaxHeight` membatasi bibir yang bisa dibantu (0,55 stud), `StepProbeDistance` mengatur jarak baca di depan roda, dan `StepClearance`, `StepMaxUpSpeed`, serta `StepMaxSupportRatio` membatasi angkatan. Dinding yang lebih tinggi tetap menjadi penghalang fisik.
- `LateralGripAcceleration` menentukan seberapa kuat cart menahan selip samping. `SteeringGripRelease` mengurangi grip ini hanya ketika tali menarik dari samping, agar cart tidak macet saat mulai berbelok. `SteeringMinSpeed` dan `SteeringFullSpeed` menentukan rentang kecepatan ketika steering bertahap aktif. `PullSteeringStartFactor` memberi torsi awal kecil khusus saat ditarik; dorongan idle tetap tidak bisa memutar cart di tempat. `SteeringTorquePerError` menentukan ketajaman belok, `SteeringDampingTorque` meredam putaran agar cart tidak berputar berlebihan, dan `MaxSteeringTorque` adalah batas torsi belok. `SteeringMinForce` mengabaikan gaya kecil.
- Semua perubahan state cart melalui `CartService`; interaksi dan cleanup melalui `CartClaimService`.
- Jalankan `stylua --check src` dan `rojo build -o build.rbxlx` untuk mengecek source. Uji tarik, dorong, lepas, mati/respawn, dan dua pemain di Studio sebelum rilis.
- File `.rbxl` adalah snapshot lokal place. Source Rojo di `src/` tetap menjadi sumber utama untuk script.
