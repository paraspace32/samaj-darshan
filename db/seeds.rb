require "zlib"

# ──────────────────────────────────────────
# Super Admin (default login for development)
# ──────────────────────────────────────────
admin = User.find_or_initialize_by(phone: "9999999999")
admin.assign_attributes(
  name: "Super Admin",
  email: "admin@samajdarshan.com",
  password: "admin123",
  role: :super_admin,
  status: :active
)
admin.save!
puts "Super Admin: phone=9999999999  password=admin123"

# ──────────────────────────────────────────
# Regions
# ──────────────────────────────────────────
regions = [
  { name_en: "Damoh",      name_hi: "दमोह",      position: 1 },
  { name_en: "Sagar",      name_hi: "सागर",      position: 2 },
  { name_en: "Jabalpur",   name_hi: "जबलपुर",    position: 3 },
  { name_en: "Bhopal",     name_hi: "भोपाल",     position: 4 },
  { name_en: "Chhatarpur", name_hi: "छतरपुर",    position: 5 },
  { name_en: "Panna",      name_hi: "पन्ना",     position: 6 },
  { name_en: "Tikamgarh",  name_hi: "टीकमगढ़",   position: 7 },
  { name_en: "Katni",      name_hi: "कटनी",      position: 8 },
  { name_en: "Indore",     name_hi: "इंदौर",     position: 9 },
  { name_en: "Other",      name_hi: "अन्य",      position: 99 }
]

regions.each do |attrs|
  slug = attrs[:name_en].parameterize
  Region.find_or_create_by!(slug: slug) do |r|
    r.assign_attributes(attrs)
  end
end
puts "Regions: #{Region.count}"

# ──────────────────────────────────────────
# Categories
# ──────────────────────────────────────────
categories = [
  { name_en: "General News",     name_hi: "सामान्य समाचार",    color: "#6366f1", position: 1 },
  { name_en: "Women's Wing",    name_hi: "महिला संगठन",       color: "#ec4899", position: 2 },
  { name_en: "Youth",            name_hi: "युवा",              color: "#f59e0b", position: 3 },
  { name_en: "Education",        name_hi: "शिक्षा",            color: "#10b981", position: 4 },
  { name_en: "Religious",        name_hi: "धार्मिक",           color: "#f97316", position: 5 },
  { name_en: "Social Work",      name_hi: "सामाजिक कार्य",    color: "#8b5cf6", position: 6 },
  { name_en: "Business",         name_hi: "व्यापार",           color: "#06b6d4", position: 7 },
  { name_en: "Awards & Honours", name_hi: "सम्मान / पुरस्कार", color: "#eab308", position: 8 }
]

categories.each do |attrs|
  slug = attrs[:name_en].parameterize
  Category.find_or_create_by!(slug: slug) do |c|
    c.assign_attributes(attrs)
  end
end
puts "Categories: #{Category.count}"

# ──────────────────────────────────────────
# PNG image generator (no external gems)
# ──────────────────────────────────────────
COVER_COLORS = [
  [ 234, 88,  12 ],  # orange
  [ 37,  99,  235 ], # blue
  [ 5,   150, 105 ], # green
  [ 217, 119, 6 ],   # amber
  [ 124, 58,  237 ], # purple
  [ 3,   105, 161 ], # sky
  [ 190, 18,  60 ],  # rose
  [ 21,  128, 61 ],  # emerald
  [ 30,  58,  95 ],  # navy
  [ 185, 28,  28 ]   # red
].freeze

def generate_png(width, height, r, g, b)
  raw_data = ""
  height.times do |y|
    raw_data << "\x00"
    width.times do |x|
      frac_x = x.to_f / width
      frac_y = y.to_f / height
      shade = 0.7 + 0.3 * (frac_x * 0.5 + frac_y * 0.5)
      raw_data << [ (r * shade).to_i.clamp(0, 255), (g * shade).to_i.clamp(0, 255), (b * shade).to_i.clamp(0, 255) ].pack("CCC")
    end
  end

  compressed = Zlib::Deflate.deflate(raw_data)

  png = "".b
  png << [ 137, 80, 78, 71, 13, 10, 26, 10 ].pack("C*")

  ihdr_data = [ width, height, 8, 2, 0, 0, 0 ].pack("N2C5")
  png << png_chunk("IHDR", ihdr_data)
  png << png_chunk("IDAT", compressed)
  png << png_chunk("IEND", "")
  png
end

def png_chunk(type, data)
  chunk = type.b + data.b
  [ data.bytesize ].pack("N") + chunk + [ Zlib.crc32(chunk) ].pack("N")
end

def attach_cover_png(record, idx)
  color = COVER_COLORS[idx % COVER_COLORS.length]
  png_data = generate_png(600, 340, *color)
  record.cover_image.attach(
    io: StringIO.new(png_data),
    filename: "cover-#{record.id}.png",
    content_type: "image/png"
  )
end

# ──────────────────────────────────────────
# Sample news (development only)
# ──────────────────────────────────────────
if Rails.env.development? && News.count.zero?
  damoh      = Region.find_by!(slug: "damoh")
  sagar      = Region.find_by!(slug: "sagar")
  jabalpur   = Region.find_by!(slug: "jabalpur")
  bhopal     = Region.find_by!(slug: "bhopal")
  chhatarpur = Region.find_by!(slug: "chhatarpur")

  general  = Category.find_by!(slug: "general-news")
  mahila   = Category.find_by!(slug: "women-s-wing")
  yuva     = Category.find_by!(slug: "youth")
  shiksha  = Category.find_by!(slug: "education")
  dharmic  = Category.find_by!(slug: "religious")
  samajik  = Category.find_by!(slug: "social-work")
  vyapar   = Category.find_by!(slug: "business")
  samman   = Category.find_by!(slug: "awards-honours")

  news_data = [
    {
      title_en: "Annual community meeting held in Damoh with record attendance",
      title_hi: "दमोह में समाज की वार्षिक बैठक में रिकॉर्ड उपस्थिति",
      content_en: "The annual community meeting was held in Damoh district with over 800 families participating, setting a new record. Discussions focused on community development, youth education, and women empowerment.\n\nThe president appealed to all members to work together for the betterment of society. Several important decisions were taken including establishment of an education fund and fixing the date for the annual conference.\n\nSpecial recognition was given to families who contributed to community welfare during the past year. A cultural program was also organized in the evening.",
      content_hi: "दमोह जिले में आयोजित वार्षिक सामाजिक बैठक में 800 से अधिक परिवारों ने भाग लिया, जो एक नया रिकॉर्ड है। बैठक में समाज के विकास, युवाओं की शिक्षा और महिला सशक्तिकरण पर विशेष चर्चा हुई।\n\nअध्यक्ष महोदय ने सभी सदस्यों से एकजुट होकर समाज की भलाई के लिए काम करने की अपील की। इस अवसर पर कई महत्वपूर्ण निर्णय लिए गए जिनमें शिक्षा कोष की स्थापना और वार्षिक सम्मेलन की तिथि निर्धारण प्रमुख हैं।\n\nबीते वर्ष समाज कल्याण में योगदान देने वाले परिवारों को विशेष सम्मान दिया गया। शाम को सांस्कृतिक कार्यक्रम का भी आयोजन किया गया।",
      region: damoh, category: general, author: admin,
      status: :published, published_at: 2.hours.ago
    },
    {
      title_en: "Women's Wing monthly meeting: health camp announced for next month",
      title_hi: "महिला संगठन की मासिक बैठक: अगले माह स्वास्थ्य शिविर की घोषणा",
      content_en: "The monthly meeting of Damoh Women's Wing saw discussions on several important topics. Special attention was given to women's health, education and self-reliance.\n\nThe president informed that a special health camp will be organized next month in collaboration with local hospitals. Free health checkups will be available for all women of the community.\n\nA skill development workshop on tailoring and handicrafts was also announced.",
      content_hi: "दमोह महिला संगठन की मासिक बैठक में इस बार कई महत्वपूर्ण विषयों पर चर्चा हुई। महिलाओं के स्वास्थ्य, शिक्षा और आत्मनिर्भरता पर विशेष ध्यान दिया गया।\n\nसंगठन की अध्यक्षा ने बताया कि अगले माह स्थानीय अस्पतालों के सहयोग से एक विशेष स्वास्थ्य शिविर का आयोजन किया जाएगा। समाज की सभी महिलाओं के लिए निःशुल्क स्वास्थ्य जांच उपलब्ध होगी।\n\nसिलाई और हस्तशिल्प पर कौशल विकास कार्यशाला की भी घोषणा की गई।",
      region: damoh, category: mahila, author: admin,
      status: :published, published_at: 5.hours.ago
    },
    {
      title_en: "Youth conference in Sagar draws 500+ registrations",
      title_hi: "सागर में युवा सम्मेलन: 500 से अधिक पंजीकरण",
      content_en: "Over 500 youth have registered for the youth conference to be held in Sagar district. The conference will feature discussions on employment, education and social responsibility.\n\nSeveral distinguished guests including industry leaders and educators will be present. Interactive sessions on career guidance and entrepreneurship are planned.\n\nA special mentorship program connecting successful professionals with young community members will be launched at the conference.",
      content_hi: "सागर जिले में आयोजित होने वाले युवा सम्मेलन के लिए अभी तक 500 से अधिक युवाओं ने पंजीकरण कराया है। सम्मेलन में रोजगार, शिक्षा और सामाजिक जिम्मेदारी पर चर्चा होगी।\n\nमुख्य अतिथि के रूप में उद्योग जगत के दिग्गज और शिक्षाविद् उपस्थित रहेंगे। करियर मार्गदर्शन और उद्यमिता पर इंटरैक्टिव सत्र आयोजित किए जाएंगे।\n\nसम्मेलन में सफल पेशेवरों को युवा समाज सदस्यों से जोड़ने वाला एक विशेष मेंटरशिप कार्यक्रम शुरू किया जाएगा।",
      region: sagar, category: yuva, author: admin,
      status: :published, published_at: 1.day.ago
    },
    {
      title_en: "Free coaching center inaugurated in Jabalpur for competitive exams",
      title_hi: "जबलपुर में प्रतियोगी परीक्षाओं के लिए निःशुल्क कोचिंग केंद्र का उद्घाटन",
      content_en: "A free coaching center for competitive examinations was inaugurated in Jabalpur yesterday. The center will provide coaching for UPSC, MPPSC, SSC and banking exams.\n\nThe initiative is funded by community donations and will support students from economically weaker sections. Experienced faculty from various coaching institutes have volunteered to teach.\n\nAdmissions are open for the first batch of 100 students.",
      content_hi: "जबलपुर में कल प्रतियोगी परीक्षाओं के लिए एक निःशुल्क कोचिंग केंद्र का उद्घाटन किया गया। केंद्र में UPSC, MPPSC, SSC और बैंकिंग परीक्षाओं की तैयारी कराई जाएगी।\n\nयह पहल समाज के दान से संचालित है और आर्थिक रूप से कमजोर वर्ग के छात्रों को सहायता प्रदान करेगी। विभिन्न कोचिंग संस्थानों के अनुभवी शिक्षकों ने स्वेच्छा से पढ़ाने की पेशकश की है।\n\nप्रथम बैच के 100 छात्रों के लिए प्रवेश प्रक्रिया शुरू हो चुकी है।",
      region: jabalpur, category: shiksha, author: admin,
      status: :published, published_at: 1.day.ago - 3.hours
    },
    {
      title_en: "Grand temple renovation ceremony in Bhopal, thousands attend",
      title_hi: "भोपाल में भव्य मंदिर जीर्णोद्धार समारोह, हजारों की उपस्थिति",
      content_en: "The renovation ceremony of the historic community temple in Bhopal was attended by thousands of devotees. The temple, originally built 150 years ago, has been restored to its original grandeur.\n\nThe renovation project, which took 18 months and was entirely funded by community contributions, included restoration of ancient murals and installation of new marble flooring.\n\nA week-long celebration with daily prayers and cultural events has been organized.",
      content_hi: "भोपाल में ऐतिहासिक सामुदायिक मंदिर के जीर्णोद्धार समारोह में हजारों श्रद्धालुओं ने भाग लिया। 150 वर्ष पुराने इस मंदिर को उसकी मूल भव्यता में पुनर्स्थापित किया गया है।\n\nजीर्णोद्धार परियोजना में 18 महीने लगे और यह पूरी तरह से समाज के योगदान से वित्तपोषित थी। इसमें प्राचीन भित्तिचित्रों की बहाली और नए संगमरमर के फर्श की स्थापना शामिल थी।\n\nदैनिक प्रार्थना और सांस्कृतिक कार्यक्रमों के साथ एक सप्ताह का उत्सव आयोजित किया गया है।",
      region: bhopal, category: dharmic, author: admin,
      status: :published, published_at: 2.days.ago
    },
    {
      title_en: "Blood donation camp organized by community youth in Chhatarpur",
      title_hi: "छतरपुर में समाज के युवाओं द्वारा रक्तदान शिविर का आयोजन",
      content_en: "Community youth organized a blood donation camp in Chhatarpur that collected over 200 units of blood. The camp was held at the community hall in collaboration with the district hospital.\n\nYoung volunteers from across the district participated enthusiastically. The collected blood will benefit patients in government hospitals.\n\nThis is the third such camp organized this year, continuing a tradition of community service.",
      content_hi: "छतरपुर में समाज के युवाओं ने एक रक्तदान शिविर का आयोजन किया जिसमें 200 से अधिक यूनिट रक्त एकत्र किया गया। यह शिविर जिला अस्पताल के सहयोग से सामुदायिक भवन में आयोजित किया गया।\n\nजिले भर से युवा स्वयंसेवकों ने उत्साहपूर्वक भाग लिया। एकत्रित रक्त सरकारी अस्पतालों के मरीजों को लाभान्वित करेगा।\n\nयह इस वर्ष का तीसरा ऐसा शिविर है, जो सामुदायिक सेवा की परंपरा को जारी रखता है।",
      region: chhatarpur, category: samajik, author: admin,
      status: :published, published_at: 2.days.ago - 5.hours
    },
    {
      title_en: "Community entrepreneur wins state-level business award",
      title_hi: "समाज के उद्यमी को मिला राज्य स्तरीय व्यापार पुरस्कार",
      content_en: "Shri Ramesh Patel from Sagar, a prominent community member, has been awarded the State Business Excellence Award for his outstanding contribution to the food processing industry.\n\nHis company employs over 300 people and has been instrumental in promoting local agricultural products. He credited his success to the community's support and values of hard work.\n\nThe community organized a felicitation ceremony in his honor.",
      content_hi: "सागर के प्रतिष्ठित समाज सदस्य श्री रमेश पटेल को खाद्य प्रसंस्करण उद्योग में उनके उत्कृष्ट योगदान के लिए राज्य व्यापार उत्कृष्टता पुरस्कार से सम्मानित किया गया है।\n\nउनकी कंपनी 300 से अधिक लोगों को रोजगार देती है और स्थानीय कृषि उत्पादों को बढ़ावा देने में सहायक रही है। उन्होंने अपनी सफलता का श्रेय समाज के सहयोग और कड़ी मेहनत के संस्कारों को दिया।\n\nसमाज ने उनके सम्मान में एक अभिनंदन समारोह का आयोजन किया।",
      region: sagar, category: samman, author: admin,
      status: :published, published_at: 3.days.ago
    },
    {
      title_en: "New community business directory launched to boost local trade",
      title_hi: "स्थानीय व्यापार बढ़ाने के लिए नई समाज व्यापार निर्देशिका लॉन्च",
      content_en: "A comprehensive business directory listing all community-owned businesses has been launched. The directory covers businesses across 9 districts and will be available both online and in print.\n\nOver 500 businesses have already been listed including shops, factories, service providers and professionals. The initiative aims to promote intra-community trade.\n\nBusiness owners can register their businesses free of charge through the community website.",
      content_hi: "समाज के स्वामित्व वाले सभी व्यवसायों को सूचीबद्ध करने वाली एक व्यापक व्यापार निर्देशिका लॉन्च की गई है। निर्देशिका 9 जिलों के व्यवसायों को कवर करती है और ऑनलाइन व प्रिंट दोनों में उपलब्ध होगी।\n\n500 से अधिक व्यवसाय पहले ही सूचीबद्ध हो चुके हैं जिनमें दुकानें, कारखाने, सेवा प्रदाता और पेशेवर शामिल हैं। इस पहल का उद्देश्य समाज के भीतर व्यापार को बढ़ावा देना है।\n\nव्यापार मालिक समाज की वेबसाइट के माध्यम से अपने व्यवसाय को निःशुल्क पंजीकृत करा सकते हैं।",
      region: damoh, category: vyapar, author: admin,
      status: :published, published_at: 3.days.ago - 6.hours
    },
    {
      title_en: "Scholarship program benefits 150 students this year",
      title_hi: "छात्रवृत्ति कार्यक्रम से इस वर्ष 150 छात्र लाभान्वित",
      content_en: "The community scholarship program has provided financial support to 150 students this academic year. Scholarships ranging from Rs 5,000 to Rs 50,000 were awarded based on merit and financial need.\n\nStudents pursuing engineering, medical, law and other professional courses have benefited. The fund was contributed by community members from across the state.\n\nApplications for the next academic year will open in June.",
      content_hi: "समाज के छात्रवृत्ति कार्यक्रम ने इस शैक्षणिक वर्ष 150 छात्रों को वित्तीय सहायता प्रदान की है। योग्यता और आर्थिक आवश्यकता के आधार पर 5,000 रुपये से 50,000 रुपये तक की छात्रवृत्तियां प्रदान की गईं।\n\nइंजीनियरिंग, मेडिकल, कानून और अन्य व्यावसायिक पाठ्यक्रमों में पढ़ने वाले छात्र लाभान्वित हुए हैं। इस कोष में राज्य भर के समाज सदस्यों ने योगदान दिया।\n\nअगले शैक्षणिक वर्ष के लिए आवेदन जून में शुरू होंगे।",
      region: jabalpur, category: shiksha, author: admin,
      status: :published, published_at: 4.days.ago
    },
    {
      title_en: "Bhopal women's self-help group earns recognition for organic products",
      title_hi: "भोपाल महिला स्वयं सहायता समूह को जैविक उत्पादों के लिए मान्यता",
      content_en: "The women's self-help group from Bhopal community has received national recognition for their organic food products. The group, comprising 25 women, produces organic pickles, papad, and spices.\n\nTheir products are now available in major supermarkets across Madhya Pradesh. The group's annual revenue has crossed Rs 20 lakhs this year.\n\nThe initiative has inspired similar groups in other districts to start their own ventures.",
      content_hi: "भोपाल समाज के महिला स्वयं सहायता समूह को उनके जैविक खाद्य उत्पादों के लिए राष्ट्रीय मान्यता मिली है। 25 महिलाओं के इस समूह ने जैविक अचार, पापड़ और मसालों का उत्पादन किया है।\n\nउनके उत्पाद अब मध्य प्रदेश के प्रमुख सुपरमार्केट में उपलब्ध हैं। समूह का वार्षिक राजस्व इस वर्ष 20 लाख रुपये को पार कर गया है।\n\nइस पहल ने अन्य जिलों के समान समूहों को अपने उद्यम शुरू करने के लिए प्रेरित किया है।",
      region: bhopal, category: mahila, author: admin,
      status: :published, published_at: 4.days.ago - 8.hours
    }
  ]

  news_data.each_with_index do |attrs, idx|
    news_item = News.create!(attrs)
    attach_cover_png(news_item, idx)
    print "."
  end

  puts "\nSample news: #{News.count} (all with cover images)"
end

# ──────────────────────────────────────────
# Magazine issues (development only)
# ──────────────────────────────────────────
if Rails.env.development? && Magazine.count.zero?
  admin = User.find_by(role: :super_admin) || User.first

  # ── Issue 1 ─────────────────────────────
  mag1 = Magazine.create!(
    title_en: "Community Voices — Inaugural Issue",
    title_hi: "समुदाय की आवाज़ — उद्घाटन अंक",
    description_en: "The very first issue of our community magazine. This landmark edition celebrates the spirit of togetherness, highlights our collective achievements in education, business and social development, and charts a bold vision for the future of the Asati community across Madhya Pradesh and beyond.",
    description_hi: "हमारी सामुदायिक पत्रिका का पहला ऐतिहासिक अंक। यह संस्करण एकजुटता की भावना का जश्न मनाता है, शिक्षा, व्यापार और सामाजिक विकास में हमारी सामूहिक उपलब्धियों को उजागर करता है, और मध्य प्रदेश तथा उससे परे असाटी समाज के भविष्य के लिए एक साहसिक दृष्टिकोण प्रस्तुत करता है।",
    issue_number: 1,
    volume: "1",
    status: :published,
    published_at: 90.days.ago
  )

  [
    {
      title_en: "The Rise of Asati Society: A Comprehensive Vision for the Future",
      title_hi: "असाटी समाज की उन्नति: भविष्य के लिए एक व्यापक दृष्टिकोण",
      content_en: "Education stands as the most important pillar for the progress of Asati society. When we look back at the past decade, we find that the community has made remarkable progress in every sphere of life.\n\nThe number of educated youth has increased significantly — not just in quantity but in quality. Today, our young people are excelling in engineering, medicine, law, and civil services. This transformation didn't happen overnight; it is the result of years of collective effort by families, teachers, and community leaders who believed that knowledge is the true wealth.\n\n\"Education is the power that can transform an entire society.\"\n\nOur culture is our identity. Preserving the rich heritage of Asati society while embracing modernity — that is true progress. The balance between tradition and innovation defines our path forward. We see this balance in our festivals, where ancient rituals are performed with the same devotion while young volunteers stream them live for diaspora families.\n\nIn the fields of business and entrepreneurship, community members have established enterprises that employ thousands. From agriculture to technology, the Asati spirit of hard work and determination shines through in every venture.\n\nThe community's governance structures have also matured. District-level committees now operate with transparent accounting, digital record-keeping, and elected leadership that reflects the diversity of our membership. This institutional strength ensures that our progress is sustainable and inclusive.\n\nThe road ahead is bright. With unity, education, and a shared vision, the Asati community will continue to rise and inspire future generations. As we publish this inaugural issue, we invite every family to see themselves in these pages — because this magazine belongs to all of us.",
      content_hi: "असाटी समाज की उन्नति के लिए शिक्षा सबसे महत्वपूर्ण स्तंभ है। जब हम पिछले एक दशक पर नजर डालते हैं तो पाते हैं कि समाज ने जीवन के हर क्षेत्र में उल्लेखनीय प्रगति की है।\n\nशिक्षित युवाओं की संख्या में न केवल मात्रा बल्कि गुणवत्ता में भी उल्लेखनीय वृद्धि हुई है। आज हमारे युवा इंजीनियरिंग, चिकित्सा, कानून और सिविल सेवाओं में उत्कृष्ट प्रदर्शन कर रहे हैं। यह बदलाव एक रात में नहीं हुआ; यह उन परिवारों, शिक्षकों और सामुदायिक नेताओं के वर्षों के सामूहिक प्रयास का परिणाम है जो मानते थे कि ज्ञान ही सच्ची संपत्ति है।\n\n\"शिक्षा वह शक्ति है जो पूरे समाज को बदल सकती है।\"\n\nहमारी संस्कृति हमारी पहचान है। असाटी समाज की समृद्ध विरासत को संरक्षित करते हुए आधुनिकता को अपनाना — यही सच्ची प्रगति है। परंपरा और नवाचार के बीच का संतुलन ही हमारे भविष्य की दिशा तय करता है।\n\nव्यापार और उद्यमिता के क्षेत्र में, समाज के सदस्यों ने ऐसे उद्यम स्थापित किए हैं जो हजारों लोगों को रोजगार देते हैं। कृषि से लेकर प्रौद्योगिकी तक, असाटी समाज की कड़ी मेहनत और दृढ़ संकल्प की भावना हर उद्यम में दिखती है।\n\nसमाज की शासन संरचनाएं भी परिपक्व हुई हैं। जिला-स्तरीय समितियां अब पारदर्शी लेखांकन, डिजिटल रिकॉर्ड-कीपिंग और निर्वाचित नेतृत्व के साथ काम करती हैं।\n\nआगे का रास्ता उज्ज्वल है। एकता, शिक्षा और साझा दृष्टिकोण के साथ, असाटी समाज आगे बढ़ता रहेगा और आने वाली पीढ़ियों को प्रेरित करेगा।",
      position: 0
    },
    {
      title_en: "Women Empowerment: The Backbone of Our Society",
      title_hi: "महिला सशक्तिकरण: हमारे समाज की रीढ़",
      content_en: "Behind every successful community stands its women — strong, resilient, and visionary. The story of women's empowerment in the Asati community is one of quiet revolution and transformative change.\n\nAcross the state, women-led self-help groups have become engines of economic independence. From pickle-making units in Bhopal to boutique fashion enterprises in Jabalpur, women entrepreneurs are redefining possibilities. In Damoh district alone, 23 women-led micro-enterprises were registered in the past year, creating employment for over 150 families.\n\nThe community's women's wing, now active in all districts, has championed causes ranging from domestic violence prevention to financial literacy. Their monthly meetings — attended by an average of 80 women per session — have become forums for sharing knowledge, resolving disputes, and planning community initiatives.\n\nRita Devi from Damoh, who started a small tailoring unit five years ago, now employs 15 women. \"The community believed in me when banks wouldn't,\" she says. \"Today I'm training the next generation of women entrepreneurs. Every woman who earns her own income gains a voice in her family.\"\n\nEducation statistics tell a powerful story: girls' enrollment in higher education has tripled in the past decade. More women are pursuing professional degrees, entering the workforce, and holding leadership positions within community organizations.\n\nThe annual Women's Excellence Awards, now in its third year, celebrates outstanding contributions in fields ranging from healthcare to agriculture. Last year's ceremony in Sagar drew over 500 attendees and was live-streamed to communities across three states.\n\nAs one community leader put it: \"When you empower a woman, you empower a family. When you empower all women, you transform an entire society.\"",
      content_hi: "हर सफल समाज के पीछे उसकी महिलाएं होती हैं — मजबूत, लचीली और दूरदर्शी। असाटी समाज में महिला सशक्तिकरण की कहानी मौन क्रांति और परिवर्तनकारी बदलाव की कहानी है।\n\nराज्य भर में, महिलाओं के नेतृत्व वाले स्वयं सहायता समूह आर्थिक स्वतंत्रता के इंजन बन गए हैं। भोपाल में अचार बनाने की इकाइयों से लेकर जबलपुर में बुटीक फैशन उद्यमों तक, महिला उद्यमी संभावनाओं को फिर से परिभाषित कर रही हैं। अकेले दमोह जिले में, पिछले वर्ष 23 महिला-नेतृत्व वाले सूक्ष्म उद्यम पंजीकृत हुए, जिससे 150 से अधिक परिवारों को रोजगार मिला।\n\nसमाज की महिला शाखा, जो अब सभी जिलों में सक्रिय है, ने घरेलू हिंसा की रोकथाम से लेकर वित्तीय साक्षरता तक के कारणों की वकालत की है। उनकी मासिक बैठकें — जिनमें प्रति सत्र औसतन 80 महिलाएं भाग लेती हैं — ज्ञान साझा करने, विवादों को सुलझाने और सामुदायिक पहल की योजना बनाने के मंच बन गई हैं।\n\nदमोह की रीता देवी, जिन्होंने पांच साल पहले एक छोटी सिलाई इकाई शुरू की थी, अब 15 महिलाओं को रोजगार देती हैं। \"जब बैंकों ने मुझ पर भरोसा नहीं किया, तब समाज ने किया,\" वे कहती हैं। \"आज मैं महिला उद्यमियों की अगली पीढ़ी को प्रशिक्षित कर रही हूं। हर महिला जो अपनी आय कमाती है, अपने परिवार में एक आवाज़ पाती है।\"\n\nशिक्षा के आंकड़े एक शक्तिशाली कहानी बताते हैं: पिछले दशक में उच्च शिक्षा में लड़कियों का नामांकन तीन गुना हो गया है।\n\nजैसा कि एक सामुदायिक नेता ने कहा: \"जब आप एक महिला को सशक्त करते हैं, तो आप एक परिवार को सशक्त करते हैं। जब आप सभी महिलाओं को सशक्त करते हैं, तो आप पूरे समाज को बदल देते हैं।\"",
      position: 1
    },
    {
      title_en: "Entrepreneurship and Business: The New Face of Community Prosperity",
      title_hi: "उद्यमिता और व्यापार: सामुदायिक समृद्धि का नया चेहरा",
      content_en: "The business landscape within the Asati community has undergone a dramatic transformation over the past decade. Where once the community was primarily agrarian, today it boasts entrepreneurs in technology, manufacturing, healthcare, and services.\n\nThe community business network, with over 500 listed enterprises, generates an estimated annual revenue of Rs 200 crore collectively. This network serves not just as a directory but as a support system — members share resources, offer mentorship, and create employment within the community.\n\nYoung entrepreneurs are particularly driving innovation. Amit Patel from Sagar launched an agri-tech startup that now serves farmers across three states. His mobile app connects small farmers directly with wholesale buyers, eliminating middlemen and increasing farmer income by an average of 25%.\n\nPriya Sharma from Bhopal built an e-commerce platform for traditional handicrafts that has already onboarded 200 artisan families. \"Our community has incredible craft traditions,\" she says. \"Technology just makes them accessible to the world.\"\n\nThe community's business fund provides seed capital to promising ventures, with over 40 startups funded in the past three years. The repayment rate exceeds 90%, demonstrating both the integrity and capability of community entrepreneurs.\n\nThe annual Business Summit, held this year in Jabalpur, brought together 300 entrepreneurs, investors, and students. Panel discussions covered topics from digital marketing to export regulations, and five new partnerships were announced.\n\nAs globalization opens new markets, the Asati business community is well-positioned to compete and thrive on a larger stage. The combination of community solidarity and individual ambition is a powerful formula for prosperity.",
      content_hi: "असाटी समाज के भीतर व्यापार परिदृश्य पिछले दशक में नाटकीय रूप से बदल गया है। जहां कभी समाज मुख्य रूप से कृषि प्रधान था, आज वहां प्रौद्योगिकी, विनिर्माण, स्वास्थ्य सेवा और सेवाओं में उद्यमी हैं।\n\n500 से अधिक सूचीबद्ध उद्यमों के साथ सामुदायिक व्यापार नेटवर्क सामूहिक रूप से अनुमानित 200 करोड़ रुपये का वार्षिक राजस्व उत्पन्न करता है। यह नेटवर्क केवल एक निर्देशिका नहीं बल्कि एक सहायता प्रणाली के रूप में कार्य करता है — सदस्य संसाधन साझा करते हैं, मार्गदर्शन प्रदान करते हैं और समाज के भीतर रोजगार सृजित करते हैं।\n\nयुवा उद्यमी विशेष रूप से नवाचार को बढ़ावा दे रहे हैं। सागर के अमित पटेल ने एक एग्री-टेक स्टार्टअप शुरू किया जो अब तीन राज्यों के किसानों की सेवा करता है। उनका मोबाइल ऐप छोटे किसानों को सीधे थोक खरीदारों से जोड़ता है।\n\nभोपाल की प्रिया शर्मा ने पारंपरिक हस्तशिल्प के लिए एक ई-कॉमर्स प्लेटफॉर्म बनाया जिसने पहले ही 200 कारीगर परिवारों को जोड़ लिया है।\n\nसमाज का व्यापार कोष आशाजनक उद्यमों को बीज पूंजी प्रदान करता है, पिछले तीन वर्षों में 40 से अधिक स्टार्टअप को वित्तपोषित किया गया है। पुनर्भुगतान दर 90% से अधिक है।\n\nजैसे-जैसे वैश्वीकरण नए बाजार खोलता है, असाटी व्यापार समुदाय बड़े मंच पर प्रतिस्पर्धा करने और फलने-फूलने के लिए अच्छी स्थिति में है।",
      position: 2
    },
    {
      title_en: "Education Report: 50 Students Clear Competitive Exams This Year",
      title_hi: "शिक्षा रिपोर्ट: इस वर्ष 50 छात्रों ने प्रतियोगी परीक्षाएं उत्तीर्ण कीं",
      content_en: "This year alone, over 50 students from the Asati community secured seats in top-tier institutions including IITs, NITs, AIIMS, and NLUs. Many of these students come from humble backgrounds, proving that determination trumps circumstances every time.\n\nThe community's free coaching centers, now operational in 5 districts across Madhya Pradesh, have played a pivotal role in this achievement. Volunteer teachers — many of whom are successful professionals giving back to the community — provide mentorship that goes beyond textbooks. They teach exam strategy, time management, and the confidence to dream big.\n\nDigital literacy initiatives have also gained momentum. Computer labs set up in community halls across Damoh, Sagar, Jabalpur, Bhopal, and Chhatarpur are helping students access resources that were previously out of reach. Online courses, video lectures, and practice tests are now available to every student with a community ID.\n\nNotable achievers this year include Rahul Vishwakarma from Damoh who secured AIR 342 in JEE Advanced, Sneha Patel from Sagar who ranked in the top 500 in NEET, and Manish Kumar from Jabalpur who cleared the UPSC preliminary examination on his first attempt.\n\n\"When I got my result, the first call I made was to my coaching center teacher,\" says Rahul. \"He taught me for free for two years. This result belongs to him and the entire community.\"\n\nAs we invest in education, we invest in our future. Every child who learns, every student who succeeds, every professional who mentors the next generation — they all contribute to a stronger, more resilient community.",
      content_hi: "इस वर्ष अकेले, असाटी समाज के 50 से अधिक छात्रों ने IIT, NIT, AIIMS और NLU जैसे शीर्ष संस्थानों में सीट हासिल की। इनमें से कई छात्र साधारण पृष्ठभूमि से आते हैं, जो साबित करता है कि दृढ़ संकल्प परिस्थितियों से हमेशा ऊपर होता है।\n\nसमाज के निःशुल्क कोचिंग केंद्र, जो अब मध्य प्रदेश के 5 जिलों में संचालित हैं, ने इस उपलब्धि में महत्वपूर्ण भूमिका निभाई है। स्वयंसेवक शिक्षक — जिनमें कई सफल पेशेवर हैं जो समाज को वापस दे रहे हैं — किताबों से परे मार्गदर्शन प्रदान करते हैं। वे परीक्षा रणनीति, समय प्रबंधन और बड़े सपने देखने का आत्मविश्वास सिखाते हैं।\n\nडिजिटल साक्षरता पहल ने भी गति पकड़ी है। दमोह, सागर, जबलपुर, भोपाल और छतरपुर में सामुदायिक भवनों में स्थापित कंप्यूटर लैब छात्रों को उन संसाधनों तक पहुंच बना रहे हैं जो पहले उनकी पहुंच से बाहर थे।\n\nइस वर्ष के उल्लेखनीय उपलब्धि हासिल करने वालों में दमोह के राहुल विश्वकर्मा शामिल हैं जिन्होंने JEE Advanced में AIR 342 हासिल की, सागर की स्नेहा पटेल जो NEET में शीर्ष 500 में रहीं, और जबलपुर के मनीष कुमार जिन्होंने अपने पहले प्रयास में UPSC प्रारंभिक परीक्षा उत्तीर्ण की।\n\n\"जब मुझे अपना परिणाम मिला, तो मैंने पहला कॉल अपने कोचिंग सेंटर के शिक्षक को किया,\" राहुल कहते हैं। \"उन्होंने मुझे दो साल तक मुफ्त पढ़ाया। यह परिणाम उनका और पूरे समाज का है।\"\n\nजब हम शिक्षा में निवेश करते हैं, तो हम अपने भविष्य में निवेश करते हैं।",
      position: 3
    },
    {
      title_en: "From the Editor's Desk: Why This Magazine Matters",
      title_hi: "संपादक की कलम से: यह पत्रिका क्यों महत्वपूर्ण है",
      content_en: "Dear readers,\n\nYou hold in your hands (or on your screens) the very first issue of our community magazine. This is not just a publication — it is a mirror that reflects who we are, a bridge that connects our past to our future, and a platform that gives voice to every member of the Asati community.\n\nFor years, our stories went untold. The brilliant student who cracked a competitive exam against all odds. The woman who built a business from her kitchen. The volunteer who donated blood at 3 AM to save a stranger's life. The elder who mediated a family dispute with wisdom and patience. These stories deserve to be told, celebrated, and shared.\n\nThis magazine is our collective voice. In these pages, you will find news, analysis, profiles, and perspectives from every corner of our community. We promise to be honest, inclusive, and forward-looking.\n\nWe need your participation to make this succeed. Write to us. Share your stories. Send us photographs. Tell us what matters to you. This magazine belongs to every one of the 50,000+ families that make up the Asati community.\n\nWith warm regards and high hopes,\nThe Editorial Team",
      content_hi: "प्रिय पाठकों,\n\nआप अपने हाथों में (या अपनी स्क्रीन पर) हमारी सामुदायिक पत्रिका का पहला अंक पकड़ रहे हैं। यह केवल एक प्रकाशन नहीं है — यह एक दर्पण है जो दर्शाता है कि हम कौन हैं, एक पुल है जो हमारे अतीत को हमारे भविष्य से जोड़ता है, और एक मंच है जो असाटी समाज के हर सदस्य को आवाज़ देता है।\n\nवर्षों से, हमारी कहानियां अनकही रहीं। वह प्रतिभाशाली छात्र जिसने सभी बाधाओं के खिलाफ प्रतियोगी परीक्षा में सफलता पाई। वह महिला जिसने अपनी रसोई से एक व्यवसाय खड़ा किया। वह स्वयंसेवक जिसने रात 3 बजे एक अजनबी की जान बचाने के लिए रक्तदान किया। वह बुजुर्ग जिसने ज्ञान और धैर्य से पारिवारिक विवाद सुलझाया। ये कहानियां बताई जाने, मनाई जाने और साझा किए जाने की हकदार हैं।\n\nयह पत्रिका हमारी सामूहिक आवाज़ है। इन पृष्ठों में, आपको हमारे समाज के हर कोने से समाचार, विश्लेषण, प्रोफ़ाइल और दृष्टिकोण मिलेंगे।\n\nइसे सफल बनाने के लिए हमें आपकी भागीदारी चाहिए। हमें लिखें। अपनी कहानियां साझा करें। हमें तस्वीरें भेजें। हमें बताएं कि आपके लिए क्या मायने रखता है।\n\nहार्दिक शुभकामनाओं और उच्च उम्मीदों के साथ,\nसंपादकीय टीम",
      position: 4
    }
  ].each do |attrs|
    mag1.magazine_articles.create!(attrs.merge(author: admin))
    print "."
  end

  # ── Issue 2 ─────────────────────────────
  mag2 = Magazine.create!(
    title_en: "Navratri Special — Tradition Meets Modernity",
    title_hi: "नवरात्रि विशेष — परंपरा और आधुनिकता का मिलन",
    description_en: "A special festive issue celebrating the nine nights of devotion, community spirit, and the beautiful blend of ancient traditions with modern expression. Featuring ground reports from Garba nights, cultural showcases, and the social impact of community festivals.",
    description_hi: "भक्ति, सामुदायिक भावना, और प्राचीन परंपराओं के आधुनिक अभिव्यक्ति के साथ सुंदर मिश्रण का जश्न मनाता एक विशेष उत्सव अंक। गरबा रात, सांस्कृतिक प्रदर्शनियों और सामुदायिक उत्सवों के सामाजिक प्रभाव की ज़मीनी रिपोर्ट।",
    issue_number: 2,
    volume: "1",
    status: :published,
    published_at: 45.days.ago
  )

  [
    {
      title_en: "Navratri Celebrations Across Madhya Pradesh: A Ground Report",
      title_hi: "मध्य प्रदेश भर में नवरात्रि उत्सव: एक ज़मीनी रिपोर्ट",
      content_en: "Every year, Navratri brings the community together in a celebration that beautifully blends ancient traditions with contemporary expression. This year's festivities across Madhya Pradesh were truly exceptional in their scale and spirit.\n\nIn Bhopal, the community organized a grand Garba night at the Asati Bhawan that attracted over 2,000 participants. What made it special was the fusion of traditional folk songs with modern music arrangements, creating an experience that resonated with both elders and youth. Professional lighting, a state-of-the-art sound system, and live streaming meant that community members from Delhi to Dubai could participate.\n\nThe nine-day celebrations included daily pujas led by rotating families, cultural performances by children's groups, and community feasts that served over 5,000 meals. Each evening brought a different theme — from classical dance presentations on Night 3 to a contemporary theatrical performance depicting the story of Durga through a modern lens on Night 7.\n\nIn Sagar, the celebrations took on a distinctly social character. Each night was dedicated to a cause — Night 1 for education, Night 2 for women's empowerment, Night 3 for health awareness, and so on. Donation drives raised over Rs 8 lakh for the community scholarship fund.\n\nDamoh's celebrations were intimate and deeply traditional. The morning Havan ceremonies drew families from across the district, and the evening Aarti at the community temple became a symbol of continuity — the same prayers, the same devotion, generation after generation.\n\nAs one elder in Jabalpur remarked: \"When our youth lead the puja with the same devotion as their grandparents, I know our traditions are in safe hands. This is what Navratri teaches us — that devotion transcends time.\"",
      content_hi: "हर साल नवरात्रि समाज को एक ऐसे उत्सव में एक साथ लाती है जो प्राचीन परंपराओं को समकालीन अभिव्यक्ति के साथ खूबसूरती से मिलाता है। इस वर्ष मध्य प्रदेश भर में उत्सव अपने पैमाने और भावना में वास्तव में असाधारण थे।\n\nभोपाल में, समाज ने असाटी भवन में एक भव्य गरबा रात का आयोजन किया जिसमें 2,000 से अधिक प्रतिभागियों ने भाग लिया। इसे विशेष बनाने वाली बात पारंपरिक लोक गीतों का आधुनिक संगीत व्यवस्थाओं के साथ मिश्रण था। पेशेवर लाइटिंग, अत्याधुनिक साउंड सिस्टम और लाइव स्ट्रीमिंग का मतलब था कि दिल्ली से दुबई तक समाज के सदस्य भाग ले सकते थे।\n\nनौ दिवसीय समारोह में बारी-बारी से परिवारों द्वारा संचालित दैनिक पूजा, बच्चों के समूहों द्वारा सांस्कृतिक कार्यक्रम, और 5,000 से अधिक भोजन परोसने वाले सामुदायिक भोज शामिल थे।\n\nसागर में, उत्सव ने एक विशेष सामाजिक चरित्र ग्रहण किया। हर रात एक कारण को समर्पित थी — रात 1 शिक्षा के लिए, रात 2 महिला सशक्तिकरण के लिए, रात 3 स्वास्थ्य जागरूकता के लिए। दान अभियानों ने सामुदायिक छात्रवृत्ति कोष के लिए 8 लाख रुपये से अधिक जुटाए।\n\nजबलपुर में एक बुजुर्ग ने कहा: \"जब हमारे युवा उसी श्रद्धा से पूजा का नेतृत्व करते हैं जैसे उनके दादा-दादी करते थे, तो मुझे पता चलता है कि हमारी परंपराएं सुरक्षित हाथों में हैं।\"",
      position: 0
    },
    {
      title_en: "The Wave of Social Change in Sagar: A Model for Community Development",
      title_hi: "सागर में सामाजिक बदलाव की लहर: सामुदायिक विकास का एक मॉडल",
      content_en: "Sagar has emerged as a model district for community-led social development. Over the past five years, the community here has undertaken initiatives that have transformed the social fabric of the region in ways that other districts are now eager to replicate.\n\nFrom organizing collective weddings that save families lakhs of rupees, to running a 24x7 helpline for community members in distress, the Sagar chapter has set benchmarks for others to follow. The collective wedding program alone has saved families an estimated Rs 2 crore in the past three years, while also sending a powerful message against excessive spending on ceremonies.\n\nThe most remarkable achievement has been the near-elimination of dowry practices within the community. Through sustained awareness campaigns — including street plays, pamphlets in both Hindi and English, and direct family counseling — and the social accountability that comes from a tight-knit community, families have embraced a new normal where marriages are celebrated, not burdened by financial demands.\n\nHealthcare initiatives have also shown impressive results. The community-run blood bank in Sagar has served over 1,000 patients in its first year of operation. A network of 40 registered blood donors is on call 24/7. Mobile health clinics, staffed by volunteer doctors from the community, visit rural areas monthly, providing free check-ups and medicines.\n\nThe Sagar chapter's dispute resolution committee has mediated over 200 family and property disputes in three years, saving members the cost and stress of litigation. \"We resolve 90% of cases within two meetings,\" says the committee head. \"Because we know the families, we can find solutions that courts never could.\"\n\nThese changes didn't come without resistance. Early advocates faced skepticism and even opposition from those who saw tradition as unchangeable. But persistence, backed by visible results and the quiet support of elders, gradually won hearts and minds. Today, Sagar's model is being studied and adopted by community chapters in Indore, Gwalior, and Rewa.",
      content_hi: "सागर सामुदायिक नेतृत्व वाले सामाजिक विकास के लिए एक मॉडल जिले के रूप में उभरा है। पिछले पांच वर्षों में, यहां के समाज ने ऐसी पहल की हैं जिन्होंने क्षेत्र के सामाजिक ताने-बाने को बदल दिया है।\n\nसामूहिक विवाह आयोजित करने से — जो परिवारों को लाखों रुपये बचाता है — लेकर संकट में समाज के सदस्यों के लिए 24x7 हेल्पलाइन चलाने तक, सागर चैप्टर ने दूसरों के लिए मानदंड स्थापित किए हैं। अकेले सामूहिक विवाह कार्यक्रम ने पिछले तीन वर्षों में परिवारों को अनुमानित 2 करोड़ रुपये बचाए हैं।\n\nसबसे उल्लेखनीय उपलब्धि समाज के भीतर दहेज प्रथा का लगभग उन्मूलन रही है। निरंतर जागरूकता अभियानों — जिसमें नुक्कड़ नाटक, हिंदी और अंग्रेजी दोनों में पैम्फलेट, और सीधे पारिवारिक परामर्श शामिल हैं — के माध्यम से, परिवारों ने एक नई सामान्य स्थिति को अपनाया है।\n\nस्वास्थ्य सेवा पहल ने भी प्रभावशाली परिणाम दिखाए हैं। सागर में समाज द्वारा संचालित ब्लड बैंक ने अपने पहले वर्ष में 1,000 से अधिक रोगियों की सेवा की है। 40 पंजीकृत रक्तदाताओं का एक नेटवर्क 24/7 उपलब्ध है।\n\nसागर चैप्टर की विवाद समाधान समिति ने तीन वर्षों में 200 से अधिक पारिवारिक और संपत्ति विवादों में मध्यस्थता की है। ये बदलाव बिना प्रतिरोध के नहीं आए, लेकिन दृश्यमान परिणामों से समर्थित दृढ़ता ने धीरे-धीरे दिलों और दिमागों को जीत लिया।",
      position: 1
    },
    {
      title_en: "Photo Essay: Colours of Community — Festival Moments Captured",
      title_hi: "फोटो निबंध: समुदाय के रंग — उत्सव के पल",
      content_en: "They say a picture is worth a thousand words. In this photo essay, we present moments from community celebrations across Madhya Pradesh that capture the essence of who we are.\n\nThe joy on a grandmother's face as she watches her granddaughter perform her first Garba. The concentration of a young boy learning to tie a turban from his grandfather. The pride in a mother's eyes at her son's graduation ceremony. The laughter shared over chai at a community meeting. The quiet dignity of morning prayers at the temple.\n\nThese images tell a story that no words fully can — the story of a community that is deeply rooted in tradition yet reaching confidently toward the future. A community where every celebration is a collective affair, where every achievement is shared, and where every challenge is faced together.\n\nWe invite our readers to share their own photographs for future issues. Whether it's a family gathering, a community event, or a simple moment of daily life that captures the Asati spirit — send it to us. Your moments are our history.\n\n(Editor's note: In future print editions, this section will feature full-colour photographs submitted by community members from across the state. For this digital edition, we encourage readers to share their favourite community moments on our social media channels.)",
      content_hi: "कहते हैं कि एक तस्वीर हजार शब्दों के बराबर होती है। इस फोटो निबंध में, हम मध्य प्रदेश भर में सामुदायिक उत्सवों के उन पलों को प्रस्तुत करते हैं जो हमारे सार को दर्शाते हैं।\n\nएक दादी के चेहरे पर खुशी जब वह अपनी पोती को पहला गरबा करते देखती है। एक छोटे लड़के का ध्यान जब वह अपने दादाजी से पगड़ी बांधना सीखता है। एक माँ की आँखों में गर्व अपने बेटे के दीक्षांत समारोह में। सामुदायिक बैठक में चाय पर साझा हँसी। मंदिर में सुबह की प्रार्थना की शांत गरिमा।\n\nये छवियां एक ऐसी कहानी बताती हैं जो कोई शब्द पूरी तरह नहीं बता सकते — एक ऐसे समाज की कहानी जो परंपरा में गहरी जड़ें रखता है फिर भी आत्मविश्वास से भविष्य की ओर बढ़ रहा है।\n\nहम अपने पाठकों को भविष्य के अंकों के लिए अपनी तस्वीरें साझा करने के लिए आमंत्रित करते हैं। चाहे वह पारिवारिक सभा हो, सामुदायिक कार्यक्रम हो, या दैनिक जीवन का एक साधारण पल जो असाटी भावना को दर्शाता है — हमें भेजें। आपके पल हमारा इतिहास हैं।",
      position: 2
    },
    {
      title_en: "Community Kitchen: Traditional Recipes from Asati Households",
      title_hi: "सामुदायिक रसोई: असाटी घरों की पारंपरिक रेसिपी",
      content_en: "Food is more than nourishment — it is memory, identity, and love. In this new recurring section, we share traditional recipes passed down through generations of Asati families.\n\nDAL BAFLA — The Festival Favourite\n\nNo Asati celebration is complete without Dal Bafla. This quintessential dish of Madhya Pradesh holds a special place at every community gathering.\n\nIngredients for Bafla: Wheat flour (2 cups), ghee (4 tbsp), salt to taste, water as needed. For Dal: Toor dal (1 cup), turmeric, red chili powder, cumin seeds, ghee, garlic, and fresh coriander.\n\nMethod: Knead a firm dough with wheat flour, ghee, salt, and water. Shape into round balls. First boil them in water for 20 minutes until they float, then bake or deep-fry until golden and crispy. For the dal, pressure cook toor dal with turmeric and salt. Prepare a tadka of ghee, cumin, garlic, and chili. Serve the bafla soaked in ghee alongside piping hot dal.\n\nKHOPRA PAAN KI CHUTNEY — The Secret Condiment\n\nEvery family has their version, but the essence remains the same — fresh coconut, betel leaves, green chilies, and a hint of jaggery, ground together into a paste that elevates any meal.\n\nWe invite readers to share their family recipes for future issues. The best submissions will be featured with full credit to the family.",
      content_hi: "भोजन पोषण से अधिक है — यह स्मृति, पहचान और प्रेम है। इस नए नियमित खंड में, हम असाटी परिवारों की पीढ़ियों से चली आ रही पारंपरिक रेसिपी साझा करते हैं।\n\nदाल बाफला — उत्सव का पसंदीदा\n\nकोई भी असाटी उत्सव दाल बाफला के बिना अधूरा है। मध्य प्रदेश का यह अनिवार्य व्यंजन हर सामुदायिक सभा में विशेष स्थान रखता है।\n\nबाफला सामग्री: गेहूं का आटा (2 कप), घी (4 बड़े चम्मच), स्वादानुसार नमक, आवश्यकतानुसार पानी। दाल के लिए: तूर दाल (1 कप), हल्दी, लाल मिर्च पाउडर, जीरा, घी, लहसुन और ताज़ा धनिया।\n\nविधि: गेहूं के आटे, घी, नमक और पानी से सख्त आटा गूंथें। गोल गोलियों का आकार दें। पहले उन्हें 20 मिनट तक पानी में उबालें जब तक वे तैरने न लगें, फिर सुनहरा और कुरकुरा होने तक बेक करें या डीप फ्राई करें। घी में भिगोए बाफले को गरमागरम दाल के साथ परोसें।\n\nहम पाठकों को भविष्य के अंकों के लिए अपनी पारिवारिक रेसिपी साझा करने के लिए आमंत्रित करते हैं।",
      position: 3
    }
  ].each do |attrs|
    mag2.magazine_articles.create!(attrs.merge(author: admin))
    print "."
  end

  # ── Issue 3 ─────────────────────────────
  mag3 = Magazine.create!(
    title_en: "Youth & Future — The Next Generation Steps Up",
    title_hi: "युवा और भविष्य — अगली पीढ़ी आगे बढ़ रही है",
    description_en: "This issue is dedicated to the young achievers and emerging leaders of the Asati community. From competitive exam toppers to startup founders, sports champions to social activists — meet the generation that will shape our tomorrow.",
    description_hi: "यह अंक असाटी समाज के युवा उपलब्धि हासिल करने वालों और उभरते नेताओं को समर्पित है। प्रतियोगी परीक्षा के टॉपर्स से लेकर स्टार्टअप संस्थापकों तक, खेल चैंपियनों से लेकर सामाजिक कार्यकर्ताओं तक — उस पीढ़ी से मिलें जो हमारे कल को आकार देगी।",
    issue_number: 3,
    volume: "1",
    status: :published,
    published_at: 5.days.ago
  )

  [
    {
      title_en: "Cover Story: Meet the 10 Young Leaders Shaping Our Community's Future",
      title_hi: "कवर स्टोरी: हमारे समाज के भविष्य को आकार देने वाले 10 युवा नेताओं से मिलें",
      content_en: "They are doctors, engineers, entrepreneurs, artists, and activists. They range in age from 18 to 35. And they are all members of the Asati community who are making waves far beyond our borders. In this cover story, we profile 10 remarkable young people.\n\n1. Dr. Kavita Patel (28, Bhopal) — Completed her MBBS from AIIMS Delhi and returned to Madhya Pradesh to set up a free weekend clinic in her village. \"I could earn more in a city hospital,\" she says, \"but my community needs me here.\"\n\n2. Rohit Vishwakarma (24, Sagar) — Founded a mobile app startup that connects rural artisans with urban buyers. His platform has already processed over Rs 50 lakh in orders and supports 300 artisan families.\n\n3. Priya Sharma (26, Jabalpur) — A civil services aspirant who cleared the MPSC examination on her first attempt and now mentors 40 students from the community through weekly online sessions.\n\n4. Aman Asati (22, Damoh) — National-level kabaddi player who represented Madhya Pradesh at the Khelo India Games. He trains at the community sports center that was built with collective donations.\n\n5. Suman Devi (30, Chhatarpur) — Runs a women's cooperative that produces organic food products sold across 4 states. Her cooperative employs 60 women and has an annual turnover of Rs 1.5 crore.\n\n6. Vikash Kumar (27, Bhopal) — Software engineer at a top MNC who volunteers every weekend teaching coding to community students. His \"Code Sundays\" program has trained over 200 students.\n\n7. Neha Patel (25, Sagar) — Award-winning journalist covering rural Madhya Pradesh. Her investigative story on water scarcity in Bundelkhand won a state-level journalism prize.\n\n8. Rajesh Asati (32, Indore) — Chartered accountant who provides free tax-filing services to community members during filing season. He estimates saving families over Rs 20 lakh collectively in CA fees.\n\n9. Ankita Sharma (23, Jabalpur) — Classical dancer who blends traditional forms with contemporary movement. She represented India at a cultural exchange in Japan last year.\n\n10. Deepak Vishwakarma (29, Damoh) — Organic farmer who converted his family's 20-acre farm to fully organic production. He now trains other farmers in the community on sustainable agriculture.\n\nThese ten individuals represent the best of what our community can produce — talent, determination, and a deep commitment to giving back. They are our present pride and our future hope.",
      content_hi: "वे डॉक्टर, इंजीनियर, उद्यमी, कलाकार और कार्यकर्ता हैं। उनकी उम्र 18 से 35 वर्ष के बीच है। और वे सभी असाटी समाज के सदस्य हैं जो हमारी सीमाओं से बहुत आगे तक प्रभाव डाल रहे हैं।\n\n1. डॉ. कविता पटेल (28, भोपाल) — AIIMS दिल्ली से MBBS पूरी करके मध्य प्रदेश लौटीं और अपने गांव में मुफ्त सप्ताहांत क्लीनिक स्थापित किया। \"मैं शहर के अस्पताल में अधिक कमा सकती थी,\" वे कहती हैं, \"लेकिन मेरे समाज को यहां मेरी जरूरत है।\"\n\n2. रोहित विश्वकर्मा (24, सागर) — एक मोबाइल ऐप स्टार्टअप की स्थापना की जो ग्रामीण कारीगरों को शहरी खरीदारों से जोड़ता है। उनके प्लेटफॉर्म ने पहले ही 50 लाख रुपये से अधिक के ऑर्डर प्रोसेस किए हैं।\n\n3. प्रिया शर्मा (26, जबलपुर) — सिविल सेवा की उम्मीदवार जिन्होंने पहले प्रयास में MPSC परीक्षा उत्तीर्ण की और अब साप्ताहिक ऑनलाइन सत्रों के माध्यम से समाज के 40 छात्रों का मार्गदर्शन करती हैं।\n\n4. अमन असाटी (22, दमोह) — राष्ट्रीय स्तर के कबड्डी खिलाड़ी जिन्होंने खेलो इंडिया गेम्स में मध्य प्रदेश का प्रतिनिधित्व किया।\n\n5. सुमन देवी (30, छतरपुर) — महिला सहकारी समिति चलाती हैं जो 4 राज्यों में बिकने वाले जैविक खाद्य उत्पाद बनाती है। उनकी सहकारी 60 महिलाओं को रोजगार देती है।\n\nये दस व्यक्ति हमारे समाज की सर्वश्रेष्ठ प्रतिभा, दृढ़ संकल्प और वापस देने की गहरी प्रतिबद्धता का प्रतिनिधित्व करते हैं। वे हमारा वर्तमान गर्व और भविष्य की आशा हैं।",
      position: 0
    },
    {
      title_en: "Innovation in Education: How Community Coaching Centers Are Changing Lives",
      title_hi: "शिक्षा में नवाचार: कैसे सामुदायिक कोचिंग केंद्र जीवन बदल रहे हैं",
      content_en: "The landscape of education is changing rapidly, and the youth of our community are at the forefront of this transformation. At the heart of this revolution are five community coaching centers that have become launchpads for student success.\n\nThe flagship center in Sagar, established in 2022, operates from the first floor of the Asati Bhawan. With 3 classrooms, a computer lab, and a library of 2,000 books, it serves 150 students daily. The center is staffed entirely by volunteers — working professionals who dedicate their evenings and weekends to teaching.\n\n\"I was a student here myself,\" says Mukesh Sharma, a software engineer who teaches mathematics every Saturday. \"Someone invested their time in me, and now it's my turn. There's no better feeling than seeing your student's name on a merit list.\"\n\nThe results speak for themselves. In the past three years, students from community coaching centers have secured 12 seats in IITs, 8 in NITs, 15 in AIIMS and other medical colleges, and 4 in National Law Universities. The success rate for competitive exams among coached students is 3x the national average.\n\nThe centers also offer specialized programs: a 6-month spoken English course, computer training certifications, and personality development workshops. These \"soft skill\" programs have proven especially valuable for first-generation professionals navigating corporate environments.\n\nDigital literacy has been a game-changer. Each center now has a computer lab with high-speed internet. Students access video lectures, practice tests, and online courses from platforms like NPTEL and Khan Academy. A WhatsApp group connects all 5 centers, allowing teachers to share resources and coordinate mock exams.\n\nThe community has invested over Rs 25 lakh in infrastructure across all centers. Every rupee came from voluntary contributions — no government funding, no corporate sponsorship. \"This is our investment in our own future,\" says the Sagar chapter president. \"And the returns are already extraordinary.\"",
      content_hi: "शिक्षा का परिदृश्य तेजी से बदल रहा है, और हमारे समाज के युवा इस बदलाव में सबसे आगे हैं। इस क्रांति के केंद्र में पांच सामुदायिक कोचिंग केंद्र हैं जो छात्र सफलता के लॉन्चपैड बन गए हैं।\n\nसागर में प्रमुख केंद्र, जो 2022 में स्थापित हुआ, असाटी भवन की पहली मंजिल से संचालित होता है। 3 कक्षाओं, एक कंप्यूटर लैब और 2,000 पुस्तकों की लाइब्रेरी के साथ, यह प्रतिदिन 150 छात्रों की सेवा करता है। केंद्र पूरी तरह स्वयंसेवकों द्वारा संचालित है।\n\n\"मैं खुद यहां का छात्र था,\" मुकेश शर्मा कहते हैं, एक सॉफ्टवेयर इंजीनियर जो हर शनिवार गणित पढ़ाते हैं। \"किसी ने अपना समय मुझमें निवेश किया, और अब मेरी बारी है।\"\n\nपरिणाम स्वयं बोलते हैं। पिछले तीन वर्षों में, सामुदायिक कोचिंग केंद्रों के छात्रों ने IIT में 12, NIT में 8, AIIMS और अन्य मेडिकल कॉलेजों में 15, और राष्ट्रीय विधि विश्वविद्यालयों में 4 सीटें हासिल की हैं।\n\nडिजिटल साक्षरता एक गेम-चेंजर रही है। प्रत्येक केंद्र में अब हाई-स्पीड इंटरनेट के साथ कंप्यूटर लैब है।\n\nसमाज ने सभी केंद्रों में बुनियादी ढांचे में 25 लाख रुपये से अधिक का निवेश किया है। हर रुपया स्वैच्छिक योगदान से आया — कोई सरकारी फंडिंग नहीं, कोई कॉर्पोरेट प्रायोजन नहीं।",
      position: 1
    },
    {
      title_en: "Sports Corner: Community Athletes Making Us Proud",
      title_hi: "खेल कॉर्नर: हमें गौरवान्वित करने वाले सामुदायिक खिलाड़ी",
      content_en: "Sports have always been a source of pride for the Asati community. This year has been particularly exceptional, with community athletes achieving recognition at district, state, and national levels.\n\nKabaddi continues to be our strongest sport. The community kabaddi team from Damoh won the district championship for the third consecutive year. Four players from the team were selected for the state squad, and Aman Asati earned a spot in the Madhya Pradesh team for the Khelo India Games.\n\nIn athletics, 17-year-old Pooja Patel from Sagar set a new district record in the 400-meter sprint at the inter-school championships. Her time of 58.2 seconds has attracted attention from the Sports Authority of India.\n\nCricket, volleyball, and wrestling also saw strong performances. The community cricket tournament, held annually during Diwali week, fielded 16 teams this year — a record. The final between Sagar XI and Bhopal Warriors drew a crowd of over 800 spectators.\n\nThe community sports fund, established two years ago, provides equipment, coaching fees, and travel support to promising athletes. This year, the fund sponsored 12 athletes for specialized training camps.\n\n\"When I step onto the field wearing the MP jersey, I carry the hopes of my entire community,\" says Aman. \"That's not pressure — that's fuel.\"",
      content_hi: "खेल हमेशा से असाटी समाज के गर्व का स्रोत रहे हैं। इस वर्ष विशेष रूप से असाधारण रहा है, जिसमें सामुदायिक खिलाड़ियों ने जिला, राज्य और राष्ट्रीय स्तर पर मान्यता प्राप्त की है।\n\nकबड्डी हमारा सबसे मजबूत खेल बना हुआ है। दमोह की सामुदायिक कबड्डी टीम ने लगातार तीसरे वर्ष जिला चैंपियनशिप जीती। टीम के चार खिलाड़ियों को राज्य दल के लिए चुना गया।\n\nएथलेटिक्स में, सागर की 17 वर्षीय पूजा पटेल ने अंतर-विद्यालय चैंपियनशिप में 400 मीटर स्प्रिंट में नया जिला रिकॉर्ड बनाया। उनके 58.2 सेकंड के समय ने भारतीय खेल प्राधिकरण का ध्यान आकर्षित किया है।\n\nक्रिकेट, वॉलीबॉल और कुश्ती में भी मजबूत प्रदर्शन देखा गया। दीवाली सप्ताह के दौरान आयोजित वार्षिक सामुदायिक क्रिकेट टूर्नामेंट में इस वर्ष 16 टीमों ने भाग लिया — एक रिकॉर्ड।\n\n\"जब मैं MP की जर्सी पहनकर मैदान में उतरता हूं, तो मैं अपने पूरे समाज की उम्मीदें लेकर चलता हूं,\" अमन कहते हैं। \"यह दबाव नहीं है — यह ईंधन है।\"",
      position: 2
    },
    {
      title_en: "Voices of the Elders: Wisdom for the Next Generation",
      title_hi: "बुजुर्गों की आवाज़: अगली पीढ़ी के लिए ज्ञान",
      content_en: "In a world moving at breakneck speed, the wisdom of elders is a compass that keeps us oriented. We spoke to five respected elders from across the community and asked them one question: \"What advice would you give to today's youth?\"\n\nShri Ramesh Prasad Asati (82, Damoh): \"Never forget where you come from. I have seen our community grow from struggling farmers to successful professionals. But the values that brought us here — honesty, hard work, respect for elders, service to others — these must never change. Technology changes, society changes, but character must remain constant.\"\n\nSmt. Savitri Devi (76, Sagar): \"Educate your daughters. I was not allowed to study beyond class 5. I made sure my three daughters all completed college. Today one is a teacher, one is a nurse, and one runs her own business. When I see them confident and independent, I know my life was not in vain.\"\n\nShri Gopal Das Vishwakarma (85, Jabalpur): \"Stay united. I have lived through times when our community had nothing — no money, no education, no representation. What we had was each other. That unity built everything you see today. Never let petty disputes break what took generations to build.\"\n\nSmt. Kamla Bai (79, Bhopal): \"Be kind. All the success in the world means nothing if you lose your humanity. Help those who are struggling. Share what you have. The greatest wealth is the blessing of someone you helped without expecting anything in return.\"\n\nShri Vishnu Prasad Patel (88, Chhatarpur): \"Have patience. The youth today want everything immediately. But the best things in life take time — building a family, earning trust, growing a business, serving the community. Plant trees whose shade you may never sit in. That is the mark of a truly great life.\"\n\nThese voices carry the weight of decades of experience. In their words, we find not just advice but a moral framework that has sustained our community through generations of change.",
      content_hi: "तेज़ रफ़्तार से आगे बढ़ती दुनिया में, बुजुर्गों का ज्ञान एक कम्पास है जो हमें सही दिशा में रखता है। हमने समाज भर के पांच सम्मानित बुजुर्गों से बात की और उनसे एक सवाल पूछा: \"आज की युवा पीढ़ी को आप क्या सलाह देंगे?\"\n\nश्री रमेश प्रसाद असाटी (82, दमोह): \"कभी मत भूलो कि तुम कहां से आए हो। मैंने हमारे समाज को संघर्षरत किसानों से सफल पेशेवरों तक बढ़ते देखा है। लेकिन जिन मूल्यों ने हमें यहां तक पहुंचाया — ईमानदारी, कड़ी मेहनत, बड़ों का सम्मान, दूसरों की सेवा — ये कभी नहीं बदलने चाहिए।\"\n\nश्रीमती सावित्री देवी (76, सागर): \"अपनी बेटियों को पढ़ाओ। मुझे कक्षा 5 से आगे पढ़ने नहीं दिया गया। मैंने सुनिश्चित किया कि मेरी तीनों बेटियों ने कॉलेज पूरा किया। आज एक शिक्षिका है, एक नर्स है, और एक अपना व्यवसाय चलाती है।\"\n\nश्री गोपाल दास विश्वकर्मा (85, जबलपुर): \"एकजुट रहो। मैंने ऐसे समय देखे हैं जब हमारे समाज के पास कुछ नहीं था। जो हमारे पास था वह एक-दूसरे का साथ था। उसी एकता ने वह सब कुछ बनाया जो आज तुम देखते हो।\"\n\nश्रीमती कमला बाई (79, भोपाल): \"दयालु बनो। दुनिया की सारी सफलता का कोई मतलब नहीं अगर तुम अपनी मानवता खो दो।\"\n\nश्री विष्णु प्रसाद पटेल (88, छतरपुर): \"धैर्य रखो। आज के युवा सब कुछ तुरंत चाहते हैं। लेकिन जीवन की सबसे अच्छी चीजों में समय लगता है। ऐसे पेड़ लगाओ जिनकी छाया में तुम शायद कभी न बैठो। यही सच्चे महान जीवन की पहचान है।\"\n\nइन आवाज़ों में दशकों के अनुभव का भार है। उनके शब्दों में, हमें न केवल सलाह मिलती है बल्कि एक नैतिक ढांचा मिलता है जिसने पीढ़ियों के बदलाव के दौरान हमारे समाज को बनाए रखा है।",
      position: 3
    }
  ].each do |attrs|
    mag3.magazine_articles.create!(attrs.merge(author: admin))
    print "."
  end

  # ── Issue 4 (draft — upcoming) ──────────
  mag4 = Magazine.create!(
    title_en: "Annual Review 2026 — A Year of Milestones",
    title_hi: "वार्षिक समीक्षा 2026 — मील के पत्थरों का वर्ष",
    description_en: "Coming soon — our comprehensive annual review covering all major achievements, events, and milestones of the Asati community in 2026.",
    description_hi: "जल्द आ रहा है — 2026 में असाटी समाज की सभी प्रमुख उपलब्धियों, कार्यक्रमों और मील के पत्थरों को कवर करने वाली हमारी व्यापक वार्षिक समीक्षा।",
    issue_number: 4,
    volume: "1",
    status: :draft
  )

  mag4.magazine_articles.create!(
    title_en: "Year in Numbers: Community Achievements at a Glance",
    title_hi: "आंकड़ों में वर्ष: सामुदायिक उपलब्धियां एक नज़र में",
    content_en: "Draft — This article will compile key statistics and achievements from across the community in 2026. Data collection is in progress from all district chapters.",
    content_hi: "ड्राफ्ट — यह लेख 2026 में समाज भर की प्रमुख सांख्यिकी और उपलब्धियों को संकलित करेगा। सभी जिला शाखाओं से डेटा संग्रह प्रगति पर है।",
    author: admin,
    position: 0
  )
  print "."

  puts "\nMagazine issues: #{Magazine.count} (#{Magazine.published.count} published, #{Magazine.draft.count} draft)"
  puts "Magazine articles: #{MagazineArticle.count}"
end

# Attach cover images to existing news that don't have one
if Rails.env.development?
  News.find_each.with_index do |news_item, idx|
    next if news_item.cover_image.attached?
    attach_cover_png(news_item, idx)
    print "+"
  end
  puts "\nAll news now have cover images."
end

# ──────────────────────────────────────
# Webinars
# ──────────────────────────────────────
puts "\n--- Seeding Webinars ---"

host = User.find_by(role: :super_admin) || User.first

webinar_data = [
  {
    title_en: "Community Leadership in the Digital Age",
    title_hi: "डिजिटल युग में सामुदायिक नेतृत्व",
    description_en: "Join us for an insightful discussion on how community leaders can leverage technology to drive positive social change. We'll explore digital tools for community engagement, social media strategies, and online organizing techniques.",
    description_hi: "सामुदायिक नेताओं द्वारा सकारात्मक सामाजिक परिवर्तन लाने के लिए तकनीक का उपयोग कैसे किया जा सकता है, इस पर एक अंतर्दृष्टिपूर्ण चर्चा में शामिल हों। हम सामुदायिक जुड़ाव के लिए डिजिटल उपकरणों, सोशल मीडिया रणनीतियों और ऑनलाइन संगठन तकनीकों का पता लगाएंगे।",
    speaker_name: "Dr. Rajesh Sharma",
    speaker_bio: "Social technologist and author with 15+ years of experience in community development",
    platform: :zoom,
    starts_at: 5.days.from_now.change(hour: 19, min: 0),
    duration_minutes: 90,
    meeting_url: "https://zoom.us/j/example1",
    status: :published
  },
  {
    title_en: "Youth Empowerment Through Education",
    title_hi: "शिक्षा के माध्यम से युवा सशक्तिकरण",
    description_en: "A comprehensive webinar focusing on educational opportunities, scholarships, and career guidance for young community members. Expert panelists will share insights on navigating higher education and professional development.",
    description_hi: "युवा सामुदायिक सदस्यों के लिए शैक्षिक अवसरों, छात्रवृत्तियों और करियर मार्गदर्शन पर केंद्रित एक व्यापक वेबिनार। विशेषज्ञ पैनलिस्ट उच्च शिक्षा और व्यावसायिक विकास पर अपनी अंतर्दृष्टि साझा करेंगे।",
    speaker_name: "Prof. Sunita Patel",
    speaker_bio: "Professor of Education at Delhi University and youth empowerment advocate",
    platform: :google_meet,
    starts_at: 12.days.from_now.change(hour: 18, min: 0),
    duration_minutes: 75,
    meeting_url: "https://meet.google.com/example2",
    status: :published
  },
  {
    title_en: "Health & Wellness in Our Community",
    title_hi: "हमारे समुदाय में स्वास्थ्य और कल्याण",
    description_en: "An interactive session on preventive health, mental wellness, and community health initiatives. Learn about free health camps, insurance schemes, and wellness programs available to community members.",
    description_hi: "निवारक स्वास्थ्य, मानसिक कल्याण और सामुदायिक स्वास्थ्य पहल पर एक इंटरैक्टिव सत्र। समुदाय के सदस्यों के लिए उपलब्ध मुफ्त स्वास्थ्य शिविरों, बीमा योजनाओं और कल्याण कार्यक्रमों के बारे में जानें।",
    speaker_name: "Dr. Meena Agarwal",
    speaker_bio: "Public health specialist and community wellness consultant",
    platform: :youtube_live,
    starts_at: 3.days.ago.change(hour: 17, min: 30),
    duration_minutes: 60,
    meeting_url: "https://youtube.com/live/example3",
    status: :published
  },
  {
    title_en: "Financial Literacy Workshop",
    title_hi: "वित्तीय साक्षरता कार्यशाला",
    description_en: "Understanding investments, savings, insurance and government schemes. This practical workshop will help community members make informed financial decisions for their families' future.",
    description_hi: "निवेश, बचत, बीमा और सरकारी योजनाओं को समझना। यह व्यावहारिक कार्यशाला समुदाय के सदस्यों को अपने परिवार के भविष्य के लिए सूचित वित्तीय निर्णय लेने में मदद करेगी।",
    speaker_name: "CA Vikram Joshi",
    speaker_bio: "Chartered Accountant and financial literacy advocate with focus on community welfare",
    platform: :zoom,
    starts_at: 10.days.ago.change(hour: 20, min: 0),
    duration_minutes: 120,
    meeting_url: "https://zoom.us/j/example4",
    status: :published
  }
]

webinar_data.each do |data|
  w = Webinar.find_or_create_by!(title_en: data[:title_en]) do |webinar|
    webinar.assign_attributes(data.merge(host: host))
  end
  puts "  Webinar: #{w.title_en} (#{w.status}, #{w.starts_at.strftime('%d %b %Y')})"
end

puts "Seeded #{Webinar.count} webinars."
