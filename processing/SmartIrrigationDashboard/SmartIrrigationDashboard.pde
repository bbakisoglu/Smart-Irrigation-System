import processing.serial.*;  // Arduino ile seri iletişim için gerekli kütüphane
import java.util.ArrayList;  // Dinamik liste yapısı (su damlaları için kullanılacak)

Serial myPort;               // Seri port nesnesi: Arduino ile bağlantıyı temsil eder
int suYuzdesi = 0;           // Su seviyesi yüzdesi (Arduino'dan gelen veri)
float suBarAnim = 0;         // Su seviyesi animasyonu için geçici değer
boolean otomatikMod = false; // Otomatik sulama modunun açık/kapalı olduğunu gösterir
float waveOffset = 0;        // Dalga animasyonu için kaydırma değeri

PFont baslikFont;            // Başlık fontu
PFont yaziFont;              // Diğer metinler için font

ArrayList<Damla> damlalar = new ArrayList<Damla>();  // Su damlası animasyonlarını tutacak liste
int damlaTimer = 0;          // Damlaların belirli aralıklarla oluşturulmasını sağlayan zamanlayıcı

void setup() {
  size(420, 480);  // Uygulama penceresinin boyutu
  smooth();        // Grafiklerin yumuşak görünmesini sağlar
  baslikFont = createFont("Georgia-Bold", 26);  // Başlık için font oluştur
  yaziFont = createFont("Segoe UI", 16);        // Metinler için font oluştur

  println(Serial.list()[0]); // Mevcut seri portları konsola yazdır (debug için)
  myPort = new Serial(this, Serial.list()[0], 9600); // İlk port ile 9600 baud hızında bağlantı kur
  myPort.bufferUntil('\n'); // Satır sonuna kadar gelen veriyi bekle
}

void draw() {
  // Arka plan rengi geçişli olarak ayarlanır
  background(lerpColor(color(240, 255, 250), color(200, 220, 255), 0.5));

  // Başlık metni çizilir
  textFont(baslikFont);
  fill(40);
  textAlign(CENTER);
  text("🌿 Bitki Sulama Paneli", width / 2, 45);

  // Otomatik mod butonu çizilir
  drawButton(width / 2 - 65, 80, 130, 50,
             otomatikMod ? color(0, 180, 120) : color(255, 80, 80),
             "Otomatik: " + (otomatikMod ? "Açık" : "Kapalı"),
             15, true);

  // Su seviyesi başlığı
  textFont(baslikFont);
  textSize(18);
  fill(0);
  text("💧 Su Seviyesi", width / 2, 155);

  // Su seviyesi çubuğu çizilir
  drawVerticalWaterBar();

  // Manuel sulama kontrol butonları
  drawButton(50, 360, 130, 40, color(70, 160, 255), " Sula: Başlat", 14, false);
  drawButton(240, 360, 130, 40, color(180, 80, 255), " Sula: Durdur", 14, false);

  // Su damlaları belirli aralıklarla oluşturulur
  damlaTimer++;
  if (damlaTimer > 10) {
    float damlaYukseklik = map(suBarAnim, 0, 100, 0, 120);
    float damlaStartY = 330 - damlaYukseklik;
    damlalar.add(new Damla(random(width / 2 - 20, width / 2 + 20), damlaStartY));
    damlaTimer = 0;
  }

  // Her damla güncellenir ve ekrana çizilir
  for (int i = damlalar.size() - 1; i >= 0; i--) {
    Damla d = damlalar.get(i);
    d.update();
    d.display();
    if (d.isGone()) {
      damlalar.remove(i); // Ekrandan çıkan damla bellekten silinir
    }
  }
}

// Buton çizim fonksiyonu
void drawButton(float x, float y, float w, float h, color c, String label, int textSizeVal, boolean centerText) {
  boolean hovering = mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h;
  fill(hovering ? lerpColor(c, color(255), 0.2) : c);
  stroke(80);
  rect(x, y, w, h, 15);
  fill(0);
  textFont(yaziFont);
  textSize(textSizeVal);
  text(label, x + w / 2, y + h / 2 + 5);
}

// Su seviyesi çubuğu ve animasyonu
void drawVerticalWaterBar() {
  suBarAnim = lerp(suBarAnim, suYuzdesi, 0.05); // Yumuşak geçiş animasyonu
  float barH = 120;
  float barW = 60;
  float suH = map(suBarAnim, 0, 100, 0, barH);
  float baseX = width / 2 - barW / 2;
  float baseY = 330;

  // Dalgalı su yüzeyi çizimi
  noStroke();
  fill(0, 150, 255, 180);
  beginShape();
  vertex(baseX, baseY);
  for (float x = 0; x <= barW; x += 2) {
    float y = sin((x + waveOffset) * 0.2) * 4;
    vertex(baseX + x, baseY - suH + y);
  }
  vertex(baseX + barW, baseY);
  endShape(CLOSE);
  waveOffset += 1.2;

  // Su çubuğu çerçevesi
  noFill();
  stroke(80);
  strokeWeight(1.2);
  rect(baseX, baseY - barH, barW, barH, 10);

  // Su yüzdesi yazısı
  fill(0);
  textFont(yaziFont);
  textSize(16);
  text(nf(suBarAnim, 1, 1) + " %", width / 2, baseY + 25);
}

// Damla sınıfı - su damlası animasyonu
class Damla {
  float x, y, speed, size, alpha;

  Damla(float x_, float y_) {
    x = x_;
    y = y_;
    speed = random(0.5, 1.2);  // Yukarı çıkma hızı
    size = random(5, 10);      // Damla boyutu
    alpha = 255;               // Saydamlık değeri
  }

  void update() {
    y -= speed;    // Yukarı hareket
    alpha -= 2;    // Saydamlaşma
  }

  void display() {
    fill(0, 120, 255, alpha);
    noStroke();
    ellipse(x, y, size, size + 3); // Damla görseli
  }

  boolean isGone() {
    return alpha <= 0 || y < 330 - 120; // Damla silinme kriteri
  }
}

// Butonlara tıklama ile veri gönderme
void mousePressed() {
  float autoBtnX = width / 2 - 65;

  // Otomatik mod değiştirildiğinde Arduino'ya veri gönder
  if (mouseX > autoBtnX && mouseX < autoBtnX + 130 && mouseY > 80 && mouseY < 130) {
    otomatikMod = !otomatikMod;
    myPort.write((otomatikMod ? "2\n" : "3\n"));
  }

  // Sulama başlat
  if (mouseX > 50 && mouseX < 180 && mouseY > 360 && mouseY < 400) {
    myPort.write("1\n");
  }

  // Sulama durdur
  if (mouseX > 240 && mouseX < 370 && mouseY > 360 && mouseY < 400) {
    myPort.write("0\n");
  }
}

// Arduino'dan gelen seri verileri işle
void serialEvent(Serial port) {
  String veri = port.readStringUntil('\n');
  if (veri != null) {
    veri = trim(veri);
    println("Gelen: " + veri);

    if (veri.startsWith("SU:")) {
      try {
        String[] parcalar = split(veri, ',');
        suYuzdesi = constrain(parseInt(parcalar[0].split(":")[1]), 0, 100);
        otomatikMod = parseInt(parcalar[1].split(":")[1]) == 1;
      } catch (Exception e) {
        println("Veri hatası: " + veri);
      }
    }
  }
}
