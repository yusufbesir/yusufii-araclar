# Klasör birleştirme planı (2026-10-10)

## Envanter
| Kaynak | Dosya | Boyut |
|---|---|---|
| C:\Users\TAA PF60V67C\Desktop\myb masaüstü | 110 | 0,42 GB |
| D:\Eğitimler | 16 | 7,47 GB |
| D:\KASA | 595 | 0,86 GB |
| D:\myb masaüstü | 28.649 | 2,50 GB (28.000+ dosyası `taabi` adlı kullanıcı profili yedeğinde) |
| D:\Programlar | 3.249 | 15,77 GB (çoğu iki Windows ISO'su ve Nebim `V3` program klasörü) |

Tam liste: `0_envanter.csv`

## Önerilen hedef yapı
```
D:\Arşiv\
  Masaüstü\     <- C:\...\Desktop\myb masaüstü  +  D:\myb masaüstü (ikisi tek klasörde birleşir, ad çakışması yok)
  Eğitimler\    <- D:\Eğitimler
  KASA\         <- D:\KASA
  Programlar\   <- D:\Programlar
```
- Alt klasörler olduğu gibi korunur. D:\ içindeki taşımalar anında olur (yeniden adlandırma), C:\ kaynağı kopyalanıp doğrulandıktan sonra kaynağı Geri Dönüşüm Kutusu'na gider.
- Ad çakışmasında üzerine yazılmaz; dosya `ad (2).uzantı` olarak taşınır ve logda belirtilir.
- 32 dosyanın yolu 240 karakteri aşıyor (C:\ RAPORLAR altındaki aylık envanter raporları); bunlar robocopy ile taşınır.

## Birebir aynı kopyalar (Geri Dönüşüm Kutusu'na) — `1_birebir_kopyalar_cop_onerisi.csv`
33 dosya, yaklaşık 400 MB. Yalnızca SHA-256 hash'i aynı **ve** adı aynı (ya da sadece "(1)", " 2" gibi kopya ekiyle farklı) olanlar. Her grupta bir kopya tutulur; öncelik düzenli klasördeki kopyadır (masaüstündeki kategorili klasörler > Eğitimler > KASA > Programlar > D:\myb masaüstü kökü / indirilenler).
- 14 program kurulum dosyası: `D:\myb masaüstü\indirilenler` içindeki kopyalar gider, `PROGRAM KURULUM DOSYALARI` içindekiler kalır (`D:\Programlar\Claude Setup.exe` de kopya).
- 15 belge: `D:\myb masaüstü` kökündeki/indirilenler'deki kopyalar gider, masaüstündeki `ŞİRKET VE ORGANİZASYON`, `SİBER GÜVENLİK VE BT`, `TUTANAK VE FORMLAR`, `YEDEKLER` içindekiler kalır.
- `e-İrsaliye eğitim videosu.mkv`: masaüstü kopyası gider, Eğitimler'deki kalır.
- KASA içinde 3 adet "(1)" / " 2" kopyası.

## Dokunulmayanlar
- **Program klasörleri içindeki aynı dosyalar** (Nebim `V3` altındaki eFatura/eIrsaliye/eArchive DLL'leri, `taabi\.codex`, `taabi\.cache`): toplam ~1,2 GB görünse de silinirse programlar bozulur, listeye alınmadı.
- **İçeriği aynı ama adı farklı** (`2_ayni_icerik_farkli_ad.csv`): ör. `vlc.exe` = `vlc-3.0.23-win32.exe`, 2026 Ağustos–Aralık CİRO ŞABLONU dosyaları (boş şablon, bilerek ayrı), `VC_redist.x64 (1).exe` = `VC_redist.arm64.exe`, 2 çift yupp görseli. Ayrıca 36 adet `~$...xlsx` Excel kilit/artık dosyası. Hiçbiri otomatik silinmez.
- **Benzer dosyalar** (`3_benzer_dosyalar.csv`): adı aynı, içeriği farklı 17 grup; ör. KASA kökündeki `DEĞİŞİM-İADE TUTANAĞI.docx` (20.07) ile TUTANAKLAR içindeki eski sürümü (23.04), iki `YETKİLENDİRME ŞABLONU`, iki `Terzi Adem Altun Departmanlar Sunumu`. Yalnızca listelenir.
