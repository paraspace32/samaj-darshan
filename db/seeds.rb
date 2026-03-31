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

  puts "\nSample articles: #{Article.count} (all with cover images)"
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
