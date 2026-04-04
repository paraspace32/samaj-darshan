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
  [234, 88,  12],  # orange
  [37,  99,  235], # blue
  [5,   150, 105], # green
  [217, 119, 6],   # amber
  [124, 58,  237], # purple
  [3,   105, 161], # sky
  [190, 18,  60],  # rose
  [21,  128, 61],  # emerald
  [30,  58,  95],  # navy
  [185, 28,  28]   # red
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
  png << [137, 80, 78, 71, 13, 10, 26, 10].pack("C*")

  ihdr_data = [width, height, 8, 2, 0, 0, 0].pack("N2C5")
  png << png_chunk("IHDR", ihdr_data)
  png << png_chunk("IDAT", compressed)
  png << png_chunk("IEND", "")
  png
end

def png_chunk(type, data)
  chunk = type.b + data.b
  [data.bytesize].pack("N") + chunk + [Zlib.crc32(chunk)].pack("N")
end

def attach_cover_png(article, idx)
  color = COVER_COLORS[idx % COVER_COLORS.length]
  png_data = generate_png(600, 340, *color)
  article.cover_image.attach(
    io: StringIO.new(png_data),
    filename: "cover-#{article.id}.png",
    content_type: "image/png"
  )
end

# ──────────────────────────────────────────
# Sample articles (development only)
# ──────────────────────────────────────────
if Rails.env.development? && Article.count.zero?
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

  articles_data = [
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

  articles_data.each_with_index do |attrs, idx|
    article = Article.create!(attrs)
    attach_cover_png(article, idx)
    print "."
  end

  puts "\nSample news articles: #{Article.where(article_type: :news).count} (all with cover images)"
end

# ──────────────────────────────────────────
# Magazine articles (development only)
# ──────────────────────────────────────────
if Rails.env.development? && Article.magazine_only.count.zero?
  damoh    = Region.find_by!(slug: "damoh")
  sagar    = Region.find_by!(slug: "sagar")
  jabalpur = Region.find_by!(slug: "jabalpur")
  bhopal   = Region.find_by!(slug: "bhopal")

  shiksha  = Category.find_by!(slug: "education")
  dharmic  = Category.find_by!(slug: "religious")
  samajik  = Category.find_by!(slug: "social-work")
  mahila   = Category.find_by!(slug: "women-s-wing")
  yuva     = Category.find_by!(slug: "youth")
  vyapar   = Category.find_by!(slug: "business")
  samman   = Category.find_by!(slug: "awards-honours")

  magazine_data = [
    {
      title_en: "The Rise of Asati Society: A Comprehensive Vision for the Future",
      title_hi: "असाटी समाज की उन्नति: भविष्य के लिए एक व्यापक दृष्टिकोण",
      content_en: "Education stands as the most important pillar for the progress of Asati society. When we look back at the past decade, we find that the community has made remarkable progress in every sphere of life.\n\nThe number of educated youth has increased significantly — not just in quantity but in quality. Today, our young people are excelling in engineering, medicine, law, and civil services. This transformation didn't happen overnight; it is the result of years of collective effort.\n\n\"Education is the power that can transform an entire society.\"\n\nOur culture is our identity. Preserving the rich heritage of Asati society while embracing modernity — that is true progress. The balance between tradition and innovation defines our path forward.\n\nIn the fields of business and entrepreneurship, community members have established enterprises that employ thousands. From agriculture to technology, the Asati spirit of hard work and determination shines through.\n\nThe road ahead is bright. With unity, education, and a shared vision, the Asati community will continue to rise and inspire future generations.",
      content_hi: "असाटी समाज की उन्नति के लिए शिक्षा सबसे महत्वपूर्ण स्तंभ है। जब हम पिछले एक दशक पर नजर डालते हैं तो पाते हैं कि समाज ने जीवन के हर क्षेत्र में उल्लेखनीय प्रगति की है।\n\nशिक्षित युवाओं की संख्या में न केवल मात्रा बल्कि गुणवत्ता में भी उल्लेखनीय वृद्धि हुई है। आज हमारे युवा इंजीनियरिंग, चिकित्सा, कानून और सिविल सेवाओं में उत्कृष्ट प्रदर्शन कर रहे हैं। यह बदलाव एक रात में नहीं हुआ; यह वर्षों के सामूहिक प्रयास का परिणाम है।\n\n\"शिक्षा वह शक्ति है जो पूरे समाज को बदल सकती है।\"\n\nहमारी संस्कृति हमारी पहचान है। असाटी समाज की समृद्ध विरासत को संरक्षित करते हुए आधुनिकता को अपनाना — यही सच्ची प्रगति है। परंपरा और नवाचार के बीच का संतुलन ही हमारे भविष्य की दिशा तय करता है।\n\nव्यापार और उद्यमिता के क्षेत्र में, समाज के सदस्यों ने ऐसे उद्यम स्थापित किए हैं जो हजारों लोगों को रोजगार देते हैं। कृषि से लेकर प्रौद्योगिकी तक, असाटी समाज की कड़ी मेहनत और दृढ़ संकल्प की भावना हर जगह दिखती है।\n\nआगे का रास्ता उज्ज्वल है। एकता, शिक्षा और साझा दृष्टिकोण के साथ, असाटी समाज आगे बढ़ता रहेगा और आने वाली पीढ़ियों को प्रेरित करेगा।",
      region: damoh, category: shiksha, author: admin,
      status: :published, published_at: 1.day.ago, article_type: :magazine
    },
    {
      title_en: "Innovation in Education: A New Direction for Society's Youth",
      title_hi: "शिक्षा में नवाचार: समाज के युवाओं की नई दिशा",
      content_en: "The landscape of education is changing rapidly, and the youth of our community are at the forefront of this transformation. From traditional classrooms to digital learning platforms, the way knowledge is acquired and shared has evolved dramatically.\n\nThis year alone, over 50 students from the community secured seats in top-tier institutions including IITs, NITs, and AIIMS. Many of these students come from humble backgrounds, proving that determination trumps circumstances.\n\nThe community's free coaching centers, now operational in 5 districts, have played a pivotal role. Volunteer teachers — many of whom are successful professionals giving back — provide mentorship that goes beyond textbooks.\n\nDigital literacy initiatives have also gained momentum. Computer labs set up in community halls across Madhya Pradesh are helping students access resources that were previously out of reach.\n\nAs we invest in education, we invest in our future. Every child who learns to code, every student who earns a degree, every professional who mentors the next generation — they all contribute to a stronger, more resilient community.",
      content_hi: "शिक्षा का परिदृश्य तेजी से बदल रहा है, और हमारे समाज के युवा इस बदलाव में सबसे आगे हैं। पारंपरिक कक्षाओं से डिजिटल लर्निंग प्लेटफॉर्म तक, ज्ञान प्राप्त करने और साझा करने का तरीका नाटकीय रूप से विकसित हुआ है।\n\nइस वर्ष अकेले, समाज के 50 से अधिक छात्रों ने IIT, NIT और AIIMS जैसे शीर्ष संस्थानों में सीट हासिल की। इनमें से कई छात्र साधारण पृष्ठभूमि से आते हैं, जो साबित करता है कि दृढ़ संकल्प परिस्थितियों से ऊपर है।\n\nसमाज के निःशुल्क कोचिंग केंद्र, जो अब 5 जिलों में संचालित हैं, ने महत्वपूर्ण भूमिका निभाई है। स्वयंसेवक शिक्षक — जिनमें कई सफल पेशेवर हैं जो समाज को वापस दे रहे हैं — किताबों से परे मार्गदर्शन प्रदान करते हैं।\n\nडिजिटल साक्षरता पहल ने भी गति पकड़ी है। मध्य प्रदेश भर के सामुदायिक भवनों में स्थापित कंप्यूटर लैब छात्रों को उन संसाधनों तक पहुंच बना रहे हैं जो पहले उनकी पहुंच से बाहर थे।\n\nजब हम शिक्षा में निवेश करते हैं, तो हम अपने भविष्य में निवेश करते हैं। हर बच्चा जो कोडिंग सीखता है, हर छात्र जो डिग्री हासिल करता है, हर पेशेवर जो अगली पीढ़ी का मार्गदर्शन करता है — वे सभी एक मजबूत, अधिक लचीले समाज में योगदान करते हैं।",
      region: sagar, category: shiksha, author: admin,
      status: :published, published_at: 3.days.ago, article_type: :magazine
    },
    {
      title_en: "The Wave of Social Change in Sagar: A Ground Report",
      title_hi: "सागर में सामाजिक बदलाव की लहर: एक ज़मीनी रिपोर्ट",
      content_en: "Sagar has emerged as a model district for community-led social development. Over the past five years, the community here has undertaken initiatives that have transformed the social fabric of the region.\n\nFrom organizing collective weddings that save families lakhs of rupees, to running a 24x7 helpline for community members in distress, the Sagar chapter has set benchmarks for others to follow.\n\nThe most remarkable achievement has been the near-elimination of dowry practices within the community. Through sustained awareness campaigns and social pressure, families have embraced a new normal where marriages are celebrated, not burdened.\n\nHealthcare initiatives have also shown impressive results. The community-run blood bank in Sagar has served over 1,000 patients in its first year. Mobile health clinics visit rural areas monthly.\n\nThese changes didn't come without resistance. Early advocates faced skepticism and even opposition. But persistence, backed by visible results, gradually won hearts and minds.",
      content_hi: "सागर सामुदायिक नेतृत्व वाले सामाजिक विकास के लिए एक मॉडल जिले के रूप में उभरा है। पिछले पांच वर्षों में, यहां के समाज ने ऐसी पहल की हैं जिन्होंने क्षेत्र के सामाजिक ताने-बाने को बदल दिया है।\n\nसामूहिक विवाह आयोजित करने से — जो परिवारों को लाखों रुपये बचाता है — लेकर संकट में समाज के सदस्यों के लिए 24x7 हेल्पलाइन चलाने तक, सागर चैप्टर ने दूसरों के लिए मानदंड स्थापित किए हैं।\n\nसबसे उल्लेखनीय उपलब्धि समाज के भीतर दहेज प्रथा का लगभग उन्मूलन रही है। निरंतर जागरूकता अभियानों और सामाजिक दबाव के माध्यम से, परिवारों ने एक नई सामान्य स्थिति को अपनाया है जहां विवाह मनाए जाते हैं, बोझ नहीं बनते।\n\nस्वास्थ्य सेवा पहल ने भी प्रभावशाली परिणाम दिखाए हैं। सागर में समाज द्वारा संचालित ब्लड बैंक ने अपने पहले वर्ष में 1,000 से अधिक रोगियों की सेवा की है। मोबाइल स्वास्थ्य क्लीनिक मासिक रूप से ग्रामीण क्षेत्रों का दौरा करते हैं।\n\nये बदलाव बिना प्रतिरोध के नहीं आए। शुरुआती समर्थकों को संदेह और यहां तक कि विरोध का सामना करना पड़ा। लेकिन दृश्यमान परिणामों से समर्थित दृढ़ता ने धीरे-धीरे दिलों और दिमागों को जीत लिया।",
      region: sagar, category: samajik, author: admin,
      status: :published, published_at: 5.days.ago, article_type: :magazine
    },
    {
      title_en: "Navratri Special: The Meeting of Tradition and Modernity",
      title_hi: "नवरात्रि विशेष: परंपरा और आधुनिकता का मिलन",
      content_en: "Every year, Navratri brings the community together in a celebration that beautifully blends ancient traditions with contemporary expression. This year's festivities across Madhya Pradesh were no exception.\n\nIn Bhopal, the community organized a grand Garba night that attracted over 2,000 participants. What made it special was the fusion of traditional folk songs with modern music arrangements, creating an experience that resonated with both elders and youth.\n\nThe nine-day celebrations included daily pujas, cultural performances, and community feasts. Each evening brought a different theme — from classical dance presentations to contemporary theatrical performances depicting stories from mythology.\n\nFood stalls run by community women's groups served traditional delicacies, with all proceeds going to the education fund. The entrepreneurial spirit was evident in the beautiful rangoli competitions and traditional dress showcases.\n\nAs one elder remarked, \"When our youth lead the puja with the same devotion as their grandparents, I know our traditions are in safe hands.\"",
      content_hi: "हर साल नवरात्रि समाज को एक ऐसे उत्सव में एक साथ लाती है जो प्राचीन परंपराओं को समकालीन अभिव्यक्ति के साथ खूबसूरती से मिलाता है। इस वर्ष मध्य प्रदेश भर में उत्सव भी इसका अपवाद नहीं था।\n\nभोपाल में, समाज ने एक भव्य गरबा रात का आयोजन किया जिसमें 2,000 से अधिक प्रतिभागियों ने भाग लिया। इसे विशेष बनाने वाली बात पारंपरिक लोक गीतों का आधुनिक संगीत व्यवस्थाओं के साथ मिश्रण था, जिसने एक ऐसा अनुभव बनाया जो बड़ों और युवाओं दोनों के साथ गूंजता था।\n\nनौ दिवसीय समारोह में दैनिक पूजा, सांस्कृतिक कार्यक्रम और सामुदायिक भोज शामिल थे। हर शाम एक अलग विषय लेकर आई — शास्त्रीय नृत्य प्रस्तुतियों से लेकर पौराणिक कथाओं को दर्शाती समकालीन नाट्य प्रस्तुतियों तक।\n\nसमाज के महिला समूहों द्वारा संचालित खाद्य स्टालों ने पारंपरिक व्यंजन परोसे, जिनकी सभी आय शिक्षा कोष में गई। सुंदर रंगोली प्रतियोगिताओं और पारंपरिक पोशाक प्रदर्शनियों में उद्यमशीलता की भावना स्पष्ट थी।\n\nजैसा कि एक बुजुर्ग ने कहा, \"जब हमारे युवा उसी श्रद्धा से पूजा का नेतृत्व करते हैं जैसे उनके दादा-दादी करते थे, तो मुझे पता चलता है कि हमारी परंपराएं सुरक्षित हाथों में हैं।\"",
      region: bhopal, category: dharmic, author: admin,
      status: :published, published_at: 7.days.ago, article_type: :magazine
    },
    {
      title_en: "Women Empowerment: The Backbone of Our Society",
      title_hi: "महिला सशक्तिकरण: हमारे समाज की रीढ़",
      content_en: "Behind every successful community stands its women — strong, resilient, and visionary. The story of women's empowerment in the Asati community is one of quiet revolution and transformative change.\n\nAcross the state, women-led self-help groups have become engines of economic independence. From pickle-making units in Bhopal to boutique fashion enterprises in Jabalpur, women entrepreneurs are redefining possibilities.\n\nThe community's women's wing, now active in all districts, has championed causes ranging from domestic violence prevention to financial literacy. Their monthly meetings have become forums for sharing knowledge, resolving disputes, and planning community initiatives.\n\nRita Devi from Damoh, who started a small tailoring unit five years ago, now employs 15 women. \"The community believed in me when banks wouldn't,\" she says. \"Today I'm training the next generation of women entrepreneurs.\"\n\nEducation statistics tell a powerful story: girls' enrollment in higher education has tripled in the past decade. More women are pursuing professional degrees, entering the workforce, and holding leadership positions within community organizations.",
      content_hi: "हर सफल समाज के पीछे उसकी महिलाएं होती हैं — मजबूत, लचीली और दूरदर्शी। असाटी समाज में महिला सशक्तिकरण की कहानी मौन क्रांति और परिवर्तनकारी बदलाव की कहानी है।\n\nराज्य भर में, महिलाओं के नेतृत्व वाले स्वयं सहायता समूह आर्थिक स्वतंत्रता के इंजन बन गए हैं। भोपाल में अचार बनाने की इकाइयों से लेकर जबलपुर में बुटीक फैशन उद्यमों तक, महिला उद्यमी संभावनाओं को फिर से परिभाषित कर रही हैं।\n\nसमाज की महिला शाखा, जो अब सभी जिलों में सक्रिय है, ने घरेलू हिंसा की रोकथाम से लेकर वित्तीय साक्षरता तक के कारणों की वकालत की है। उनकी मासिक बैठकें ज्ञान साझा करने, विवादों को सुलझाने और सामुदायिक पहल की योजना बनाने के मंच बन गई हैं।\n\nदमोह की रीता देवी, जिन्होंने पांच साल पहले एक छोटी सिलाई इकाई शुरू की थी, अब 15 महिलाओं को रोजगार देती हैं। \"जब बैंकों ने मुझ पर भरोसा नहीं किया, तब समाज ने किया,\" वे कहती हैं। \"आज मैं महिला उद्यमियों की अगली पीढ़ी को प्रशिक्षित कर रही हूं।\"\n\nशिक्षा के आंकड़े एक शक्तिशाली कहानी बताते हैं: पिछले दशक में उच्च शिक्षा में लड़कियों का नामांकन तीन गुना हो गया है। अधिक महिलाएं पेशेवर डिग्री हासिल कर रही हैं, कार्यबल में प्रवेश कर रही हैं और सामुदायिक संगठनों में नेतृत्व पदों पर आसीन हो रही हैं।",
      region: jabalpur, category: mahila, author: admin,
      status: :published, published_at: 10.days.ago, article_type: :magazine
    },
    {
      title_en: "Entrepreneurship and Business: The New Face of Community Prosperity",
      title_hi: "उद्यमिता और व्यापार: सामुदायिक समृद्धि का नया चेहरा",
      content_en: "The business landscape within the Asati community has undergone a dramatic transformation over the past decade. Where once the community was primarily agrarian, today it boasts entrepreneurs in technology, manufacturing, healthcare, and services.\n\nThe community business network, with over 500 listed enterprises, generates an estimated annual revenue of Rs 200 crore collectively. This network serves not just as a directory but as a support system — members share resources, offer mentorship, and create employment within the community.\n\nYoung entrepreneurs are particularly driving innovation. Amit Patel from Sagar launched an agri-tech startup that now serves farmers across three states. Priya Sharma from Bhopal built an e-commerce platform for traditional handicrafts.\n\nThe community's business fund provides seed capital to promising ventures, with over 40 startups funded in the past three years. The repayment rate exceeds 90%, demonstrating both the integrity and capability of community entrepreneurs.\n\nAs globalization opens new markets, the Asati business community is well-positioned to compete and thrive on a larger stage.",
      content_hi: "असाटी समाज के भीतर व्यापार परिदृश्य पिछले दशक में नाटकीय रूप से बदल गया है। जहां कभी समाज मुख्य रूप से कृषि प्रधान था, आज वहां प्रौद्योगिकी, विनिर्माण, स्वास्थ्य सेवा और सेवाओं में उद्यमी हैं।\n\n500 से अधिक सूचीबद्ध उद्यमों के साथ सामुदायिक व्यापार नेटवर्क सामूहिक रूप से अनुमानित 200 करोड़ रुपये का वार्षिक राजस्व उत्पन्न करता है। यह नेटवर्क केवल एक निर्देशिका नहीं बल्कि एक सहायता प्रणाली के रूप में कार्य करता है — सदस्य संसाधन साझा करते हैं, मार्गदर्शन प्रदान करते हैं और समाज के भीतर रोजगार सृजित करते हैं।\n\nयुवा उद्यमी विशेष रूप से नवाचार को बढ़ावा दे रहे हैं। सागर के अमित पटेल ने एक एग्री-टेक स्टार्टअप शुरू किया जो अब तीन राज्यों के किसानों की सेवा करता है। भोपाल की प्रिया शर्मा ने पारंपरिक हस्तशिल्प के लिए एक ई-कॉमर्स प्लेटफॉर्म बनाया।\n\nसमाज का व्यापार कोष आशाजनक उद्यमों को बीज पूंजी प्रदान करता है, पिछले तीन वर्षों में 40 से अधिक स्टार्टअप को वित्तपोषित किया गया है। पुनर्भुगतान दर 90% से अधिक है, जो सामुदायिक उद्यमियों की ईमानदारी और क्षमता दोनों को दर्शाता है।\n\nजैसे-जैसे वैश्वीकरण नए बाजार खोलता है, असाटी व्यापार समुदाय बड़े मंच पर प्रतिस्पर्धा करने और फलने-फूलने के लिए अच्छी स्थिति में है।",
      region: sagar, category: vyapar, author: admin,
      status: :published, published_at: 14.days.ago, article_type: :magazine
    }
  ]

  magazine_data.each_with_index do |attrs, idx|
    article = Article.create!(attrs)
    attach_cover_png(article, idx + 10)
    print "."
  end

  puts "\nMagazine articles: #{Article.magazine_only.count} (all with cover images)"
end

# Attach cover images to existing articles that don't have one
if Rails.env.development?
  Article.find_each.with_index do |article, idx|
    next if article.cover_image.attached?
    attach_cover_png(article, idx)
    print "+"
  end
  puts "\nAll articles now have cover images."
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
