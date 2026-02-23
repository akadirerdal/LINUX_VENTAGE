# Lenovo Vantage (Linux Edition -- Intel Arc Odaklı)

Selamlar.

Lenovo Vantage arayıp Linux'ta karşılığını bulamayanlar için yazılmış
bir güç yönetim scripti.

Amaç: - Güç modlarını kontrol etmek - Intel Arc GPU runtime yönetimi
sağlamak - Hibrit / Tasarruf / Performans geçişi yapmak - Gerçek zamanlı
sıcaklık takibi sunmak

Fan kontrolü şu an doğrudan script'e bağlı değil.

Bu proje geliştirme aşamasında.

------------------------------------------------------------------------

# Gereksinimler

## Donanım

-   Lenovo laptop (Hybrid destekli BIOS önerilir)
-   Intel Arc ekran kartı (şu an için optimize edilen GPU)
-   Dahili Intel iGPU mevcut olmalı

## Yazılım

-   Linux (Wayland ortamında test edildi)
-   bash
-   sudo erişimi
-   lm_sensors
-   ccze

Kurulum:

``` bash
sudo pacman -S lm_sensors ccze
```

------------------------------------------------------------------------

# BIOS Ayarı (Zorunlu)

BIOS → Hybrid Mode aktif olmalı

Eğer Hybrid kapalıysa:

-   Harici GPU kapatıldığında ekran gider
-   Sistem görüntü vermez

------------------------------------------------------------------------

# Script İzinleri

Script tüm sysfs güç yollarına müdahale ettiği için:

``` bash
chmod 777 script.sh
sudo ./script.sh
```

Root olmadan çalışmaz.

------------------------------------------------------------------------

# Güç Modları

## 🔵 Extra Tasarruf Modu

En agresif güç tasarrufu modu.

Yapılanlar:

-   Harici GPU minimum moda alınır
-   Runtime power auto yapılır
-   Gereksiz güç tüketimi kesilir
-   CPU tasarruf moduna geçer

Tam şarjda yaklaşık 4 -- 4.5 saat alınabilir.

------------------------------------------------------------------------

## ⚠ KRİTİK UYARI -- Extra Tasarruf Modu

Bu mod aktifken sistemi kapatırsan:

-   Harici GPU initialize olmayabilir
-   Açılışta siyah ekran oluşabilir
-   Görüntü gelmeyebilir

Sebep: BIOS başlatma sırasında GPU'nun kapalı durumda kalması.

### Eğer ekran gelmezse:

1.  BIOS'a gir
2.  Discrete GPU'yu tekrar aktif et

veya

3.  Laptopu şarja takıp yeniden başlat

Bu moddayken sistemi kapatman önerilmez.

------------------------------------------------------------------------

## ⚪ Hibrit Mod

Sistem ihtiyaca göre karar verir.

-   Hafif yük → iGPU
-   Yüksek yük → dGPU
-   Dengeli güç tüketimi

Günlük kullanım için ideal mod.

------------------------------------------------------------------------

## 🔴 Performans Modu

Maksimum güç.

-   Dahili + harici GPU aktif
-   Turbo açık
-   Güç kısıtı yok
-   Oyunlarda ciddi performans artışı

### Önemli:

Bu mod şarjdayken kullanılmalı.

Sebep:

-   Fan kontrolü script'e bağlı değil
-   BIOS fan eğrisi devrede
-   Uzun yükte ısınma olabilir

------------------------------------------------------------------------

# Fan Modu Önerisi (Fn + Q)

Fan kontrolü BIOS üzerinden yapılır.

Lenovo sistemlerde genelde:

-   🔵 Mavi → Extra Tasarruf
-   ⚪ Beyaz → Hibrit
-   🔴 Kırmızı → Performans

Fn + Q ile değiştirilir.\
Güç tuşu üzerindeki renk aktif fan profilini gösterir.

Script fanları kontrol etmez.

------------------------------------------------------------------------

# Sensors Terminali

Script çalışınca yan tarafta ayrı bir terminal açılır.

Bu terminal:

-   sensors
-   Renkli çıktı (ccze)
-   1 saniyede bir yenilenir

Script kapanınca o terminal de kapanır.

------------------------------------------------------------------------

# Çalışma Mantığı

Script:

-   /sys/class/drm üzerinden GPU power control yönetir
-   /sys/devices/system/cpu üzerinden governor değiştirir
-   Turbo durumunu kontrol eder
-   Runtime status gösterir
-   Pil yüzdesi ve tahmini süre hesaplar
-   Manuel modda GPU aç/kapa sağlar

Root erişimi gerektirir çünkü doğrudan kernel sysfs yollarına yazar.

------------------------------------------------------------------------

# Sınırlamalar

-   Şu an Intel Arc odaklı
-   NVIDIA / AMD için test edilmedi
-   Fan kontrolü yok
-   Wayland dışında test edilmedi
-   Extra Tasarruf modunda sistem kapatma risklidir
-   BIOS Hybrid kapalıysa ekran gider

------------------------------------------------------------------------

# Gelecek Planı

-   Fan kontrol entegrasyonu
-   NVIDIA / AMD destek
-   Daha stabil mod geçişleri
-   Otomatik güvenlik kontrolü
-   Daha temiz UI

------------------------------------------------------------------------

# Son Söz

Bu proje kurumsal bir yazılım değil.

Bu, Linux'ta Lenovo Vantage eksikliğine sinir olmuş bir kullanıcının
yazdığı güç kontrol scripti.

Deneysel.\
Gelişiyor.\
Risk içeriyor.

Ama çalışıyor.

Geliştirmeye devam edeceğim.
