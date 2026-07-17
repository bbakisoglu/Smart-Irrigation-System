#include <SoftwareSerial.h>

const int suSensorPin = A1;    // Su seviye sensörü
const int nemSensorPin = A0;   // Toprak nem sensörü
const int kirmiziLed = 9;
const int yesilLed = 8;
const int motorIN1 = 5;
const int motorIN2 = 6;
const int motorENA = 3;

SoftwareSerial BT(10, 11); // Bluetooth bağlantısı 

bool otomatikMod = true;
bool manuelSulama = false;

void setup() 
{
  Serial.begin(9600); //Arduino ile bilgisayar arasındaki seri haberleşmeyi başlat (9600 baud hızında)
  BT.begin(9600); //Bluetooth modülü ile seri haberleşmeyi başlat (9600 baud hızında)

  pinMode(nemSensorPin, INPUT); //Nem sensörü pinini giriş olarak ayarla
  pinMode(suSensorPin, INPUT); //Su seviye sensörü pinini giriş olarak ayarla
  pinMode(motorIN1, OUTPUT); //Motorun IN1 kontrol pinini çıkış olarak ayarla
  pinMode(motorIN2, OUTPUT); //Motorun IN2 kontrol pinini çıkış olarak ayarla
  pinMode(motorENA, OUTPUT); //Motorun hız kontrol pinini(ENA) pinini çıkış olarak ayarla
  pinMode(kirmiziLed, OUTPUT); //Kırmızı LED pinini çıkış olarak ayarla
  pinMode(yesilLed, OUTPUT); //Yeşil LED pinini çıkış olarak ayarla
}

void loop() 
{
  if (BT.available() > 0) //Bluetooth üzerinden gelen veri varsa işle
   {
    String gelen = BT.readStringUntil('\n');//Satır sonuna kadar veriyi oku
    gelen.trim();//Gereksiz boşlukları sil
    komutIsle(gelen);//Komutu işle
  }

  if (Serial.available() > 0) //Bilgisayardan(Processing) gelen veri varsa işle
  {
    String gelen = Serial.readStringUntil('\n');//Satır sonuna kadar veriyi oku
    gelen.trim();//Gereksiz boşlukları sil
    komutIsle(gelen);//Komutu işle
  }

  int nemDegeri = analogRead(nemSensorPin);//Toprağın nem değerini oku
  int suSeviyeDegeri = analogRead(suSensorPin);//Su tankının seviye değerini oku
  int suYuzde = map(suSeviyeDegeri, 0, 1023, 0, 100);// 0-1023 arası analog değeri yüzdeye çevir

  // LED'lerle su seviyesi uyarısı
  if (suYuzde >= 20) {
    digitalWrite(yesilLed, HIGH);//Yeterli su varsa led yeşil yanar
    digitalWrite(kirmiziLed, LOW);//Kırmızı led sönük
  } else {
    digitalWrite(yesilLed, LOW);//Yetersiz su varsa yeşil led sönük
    digitalWrite(kirmiziLed, HIGH);//Kırmızı led yanar
  }

  // OTOMATİK MOD: Nem > 600 VE su > %20 ise motor çalışsın
  if (otomatikMod && !manuelSulama) {
    if (nemDegeri > 600 && suYuzde > 20) {
      calistirMotor();
    } else {
      durdurMotor();
    }
  }

  // Modlar kapalıysa motoru durdur
  if (!otomatikMod && !manuelSulama) {
    durdurMotor();
  }

  // Seri port üzerinden Processing'e veri gönder
  Serial.print("SU:");
  Serial.print(suYuzde);
  Serial.print(",OTOMATIK:");
  Serial.print(otomatikMod ? 1 : 0);// Otomatik mod açık mı (1) değil mi (0)
  Serial.print(",NEM:");
  Serial.println(nemDegeri);

  delay(500);
}

void komutIsle(String gelen)//Gelen komutlara göre işlem yapan fonksiyon
{
  if (gelen == "0") {
    manuelSulama = false;//Manuel sulamayı durdur
    durdurMotor();
  } else if (gelen == "1") {
    manuelSulama = true;//Manuel sulamayı başlat
    calistirMotor();
  } else if (gelen == "2") {
    otomatikMod = true;//Otomatik modu aktif et
  } else if (gelen == "3") {
    //Tüm modları kapat ve motoru durdur
    otomatikMod = false;
    manuelSulama = false;
    durdurMotor();
  }
}

void calistirMotor()//Motoru çalıştıran fonksiyon
{
  digitalWrite(motorIN1, HIGH);//Motor yönü için IN1 aktif
  digitalWrite(motorIN2, LOW);//Motor yönü için IN2 aktif
  analogWrite(motorENA, 255);//Motoru tam hızda çalıştır
}

void durdurMotor()//Motoru durduran fonksiyon
{
  digitalWrite(motorIN1, LOW);//IN1 pasif
  digitalWrite(motorIN2, LOW);//IN2 pasif
  analogWrite(motorENA, 0);//Hız=0, motoru durdur
}