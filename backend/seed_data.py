from app.database import SessionLocal, engine
from app import models, auth

# Make sure tables exist
models.Base.metadata.create_all(bind=engine)

db = SessionLocal()

try:
    # 1. Seed Users
    if not db.query(models.User).filter(models.User.username == "admin").first():
        admin = models.User(
            username="admin",
            email="admin@bookseller.com",
            full_name="Quản trị viên",
            hashed_password=auth.hash_password("admin123"),
            role=models.UserRoleEnum.admin,
            status=models.UserStatusEnum.active,
            phone="0987654321",
            address="Hà Nội, Việt Nam"
        )
        db.add(admin)
        print("Tạo tài khoản Admin -> admin / admin123")

    if not db.query(models.User).filter(models.User.username == "user1").first():
        user1 = models.User(
            username="user1",
            email="user1@gmail.com",
            full_name="Nguyễn Văn Khách",
            hashed_password=auth.hash_password("user123"),
            role=models.UserRoleEnum.customer,
            status=models.UserStatusEnum.active,
            phone="0912345678",
            address="TP. Hồ Chí Minh, Việt Nam"
        )
        db.add(user1)
        print("Tạo tài khoản Khách -> user1 / user123")

    if not db.query(models.User).filter(models.User.username == "user2").first():
        user2 = models.User(
            username="user2",
            email="user2@gmail.com",
            full_name="Trần Thị Người Mua",
            hashed_password=auth.hash_password("user123"),
            role=models.UserRoleEnum.customer,
            status=models.UserStatusEnum.active,
            phone="0911223344",
            address="Đà Nẵng, Việt Nam"
        )
        db.add(user2)
        print("Tạo tài khoản Khách -> user2 / user123")

    # 2. Seed Categories
    categories = [
        "Văn học", "Kinh tế", "Kỹ năng sống", "Giáo dục", "Truyện tranh", "Sách thiếu nhi"
    ]
    db_categories = {}
    for cat_name in categories:
        cat = db.query(models.Category).filter(models.Category.name == cat_name).first()
        if not cat:
            cat = models.Category(name=cat_name)
            db.add(cat)
            db.commit()
            db.refresh(cat)
            print(f"Thêm thể loại -> {cat_name}")
        db_categories[cat_name] = cat

    # 3. Seed Authors
    authors = [
        {"name": "Haruki Murakami", "bio": "Nhà văn Nhật Bản nổi tiếng thế giới"},
        {"name": "Nguyễn Nhật Ánh", "bio": "Nhà văn Việt Nam nổi tiếng chuyên viết cho thanh thiếu niên"},
        {"name": "Dale Carnegie", "bio": "Nhà văn và nhà thuyết trình người Mỹ"},
        {"name": "Tony Buổi Sáng", "bio": "Tác giả ẩn danh truyền cảm hứng cho giới trẻ Việt Nam"},
        {"name": "Fujiko F. Fujio", "bio": "Họa sĩ truyện tranh Nhật Bản, tác giả Doraemon"},
        {"name": "J.K. Rowling", "bio": "Nhà văn người Anh, tác giả loạt truyện Harry Potter"},
        {"name": "Paulo Coelho", "bio": "Tiểu thuyết gia nổi tiếng người Brazil, tác giả Nhà Giả Kim"},
        {"name": "Tô Hoài", "bio": "Nhà văn nổi tiếng thế kỷ 20, tác giả Dế Mèn Phiêu Lưu Ký"},
        {"name": "Stephen R. Covey", "bio": "Chuyên gia giáo dục và phát triển kỹ năng người Mỹ"},
        {"name": "Napoleon Hill", "bio": "Tác giả người Mỹ tiên phong trong thể loại thành công học"},
        {"name": "Robert Kiyosaki", "bio": "Doanh nhân và tác giả loạt sách dạy con làm giàu"},
        {"name": "Dan Senor", "bio": "Nhà văn và cố vấn chính trị người Mỹ"},
        {"name": "J.D. Salinger", "bio": "Nhà văn Mỹ nổi tiếng thế kỷ 20"},
        {"name": "Hector Malot", "bio": "Văn sĩ người Pháp chuyên viết truyện thiếu nhi"}
    ]
    db_authors = {}
    for aut_data in authors:
        aut = db.query(models.Author).filter(models.Author.name == aut_data["name"]).first()
        if not aut:
            aut = models.Author(name=aut_data["name"], bio=aut_data["bio"])
            db.add(aut)
            db.commit()
            db.refresh(aut)
            print(f"Thêm tác giả -> {aut_data['name']}")
        db_authors[aut_data["name"]] = aut

    # 4. Seed Publishers
    publishers = [
        {"name": "NXB Trẻ", "address": "TP.HCM"},
        {"name": "NXB Kim Đồng", "address": "Hà Nội"},
        {"name": "NXB Hội Nhà Văn", "address": "Hà Nội"},
        {"name": "NXB Nhã Nam", "address": "Hà Nội"},
        {"name": "NXB Thế Giới", "address": "Hà Nội"},
        {"name": "NXB Giáo Dục", "address": "Hà Nội"}
    ]
    db_publishers = {}
    for pub_data in publishers:
        pub = db.query(models.Publisher).filter(models.Publisher.name == pub_data["name"]).first()
        if not pub:
            pub = models.Publisher(name=pub_data["name"], address=pub_data["address"])
            db.add(pub)
            db.commit()
            db.refresh(pub)
            print(f"Thêm nhà xuất bản -> {pub_data['name']}")
        db_publishers[pub_data["name"]] = pub

    db.commit()

    # 5. Seed Books
    books_data = [
        {
            "title": "Mắt Biếc",
            "author_name": "Nguyễn Nhật Ánh",
            "category_name": "Văn học",
            "publisher_name": "NXB Trẻ",
            "isbn": "9786041142232",
            "price": 110000,
            "discount_price": 95000,
            "description": "Một trong những tác phẩm tiêu biểu của Nguyễn Nhật Ánh, kể về tình yêu thầm lặng của Ngạn dành cho Hà Lan.",
            "stock": 25,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/9/92/Mat_Biec.gif",
            "is_best_selling": True
        },
        {
            "title": "Rừng Na Uy",
            "author_name": "Haruki Murakami",
            "category_name": "Văn học",
            "publisher_name": "NXB Hội Nhà Văn",
            "isbn": "9786049692435",
            "price": 135000,
            "discount_price": 115000,
            "description": "Tác phẩm xuất sắc của Murakami về những năm tháng tuổi trẻ nổi loạn và cô đơn của Toru Watanabe.",
            "stock": 15,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/6/62/R%E1%BB%ABng_Na_Uy.jpg",
            "is_best_selling": False
        },
        {
            "title": "Đắc Nhân Tâm",
            "author_name": "Dale Carnegie",
            "category_name": "Kỹ năng sống",
            "publisher_name": "NXB Trẻ",
            "isbn": "9786041133333",
            "price": 86000,
            "discount_price": 72000,
            "description": "Cuốn sách kỹ năng kinh điển nhất mọi thời đại về nghệ thuật giao tiếp và thu phục lòng người.",
            "stock": 50,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/0/0a/%C4%90%E1%BA%AFc_nh%C3%A2n_t%C3%A2m.jpg",
            "is_best_selling": True
        },
        {
            "title": "Trên Đường Băng",
            "author_name": "Tony Buổi Sáng",
            "category_name": "Kỹ năng sống",
            "publisher_name": "NXB Trẻ",
            "isbn": "9786041065611",
            "price": 80000,
            "discount_price": 68000,
            "description": "Tập hợp những bài viết bổ ích của dượng Tony định hướng hành trang cho người trẻ bước vào đời.",
            "stock": 30,
            "cover_image": "https://www.nxbtre.com.vn/Images/Book/nxbtre_full_12282017_032853.jpg",
            "is_best_selling": True
        },
        {
            "title": "Doraemon Tập 1",
            "author_name": "Fujiko F. Fujio",
            "category_name": "Truyện tranh",
            "publisher_name": "NXB Kim Đồng",
            "isbn": "9786042168397",
            "price": 25000,
            "discount_price": None,
            "description": "Câu chuyện mở đầu cho hành trình phiêu lưu của chú mèo máy thông minh Doraemon và Nobita.",
            "stock": 100,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/b/b7/Doraemon1.jpg",
            "is_best_selling": False
        },
        {
            "title": "Harry Potter và Hòn Đá Phù Thủy",
            "author_name": "J.K. Rowling",
            "category_name": "Sách thiếu nhi",
            "publisher_name": "NXB Trẻ",
            "isbn": "9786041132222",
            "price": 145000,
            "discount_price": 125000,
            "description": "Tập đầu tiên mở ra thế giới phù thủy kỳ bí của cậu bé Harry Potter tại trường Hogwarts.",
            "stock": 20,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/5/5a/Harry_Potter_v%C3%A0_H%C3%B2n_%C4%91%C3%A1_Ph%C3%B9_th%E1%BB%A7y.jpg",
            "is_best_selling": True
        },
        {
            "title": "Harry Potter và Phòng Chứa Bí Mật",
            "author_name": "J.K. Rowling",
            "category_name": "Sách thiếu nhi",
            "publisher_name": "NXB Trẻ",
            "isbn": "9786041132223",
            "price": 155000,
            "discount_price": 139000,
            "description": "Năm học thứ hai đầy thử thách của Harry Potter với sinh vật đáng sợ ẩn náu trong Hogwarts.",
            "stock": 15,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/1/1b/Harry_Potter_v%C3%A0_Ph%C3%B2ng_ch%C1%BB%A9a_B%C3%AD_m%E1%BA%ADt.jpg",
            "is_best_selling": False
        },
        {
            "title": "Tôi Thấy Hoa Vàng Trên Cỏ Xanh",
            "author_name": "Nguyễn Nhật Ánh",
            "category_name": "Văn học",
            "publisher_name": "NXB Trẻ",
            "isbn": "9786041056561",
            "price": 125000,
            "discount_price": 105000,
            "description": "Cuốn tiểu thuyết xúc động về tuổi thơ nghèo khó ở làng quê nghèo miền Trung với những tình bạn, tình anh em hồn nhiên.",
            "stock": 35,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/8/89/T%C3%B4i_th%E1%BA%A5y_hoa_v%C3%A0ng_tr%C3%AAn_c%E1%BB%8F_xanh.jpg",
            "is_best_selling": True
        },
        {
            "title": "Cho Tôi Xin Một Vé Đi Tuổi Thơ",
            "author_name": "Nguyễn Nhật Ánh",
            "category_name": "Văn học",
            "publisher_name": "NXB Trẻ",
            "isbn": "9786041042312",
            "price": 95000,
            "discount_price": 79000,
            "description": "Một tấm vé đưa người đọc trở về những tháng ngày thơ ấu tinh nghịch với góc nhìn ngộ nghĩnh của thế giới trẻ thơ.",
            "stock": 40,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/a/ae/Cho_t%C3%B4i_xin_m%E1%BB%99t_v%C3%A9_%C4%91i_tu%E1%BB%95i_th%C6%A1.jpg",
            "is_best_selling": True
        },
        {
            "title": "Nhà Giả Kim",
            "author_name": "Paulo Coelho",
            "category_name": "Văn học",
            "publisher_name": "NXB Hội Nhà Văn",
            "isbn": "9786049694312",
            "price": 89000,
            "discount_price": 75000,
            "description": "Hành trình theo đuổi vận mệnh của cậu bé chăn cừu Santiago đã truyền cảm hứng sống cho hàng triệu độc giả toàn cầu.",
            "stock": 50,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/c/c4/Nh%C3%A0_gi%E1%BA%A3_kim.jpg",
            "is_best_selling": True
        },
        {
            "title": "Dế Mèn Phiêu Lưu Ký",
            "author_name": "Tô Hoài",
            "category_name": "Sách thiếu nhi",
            "publisher_name": "NXB Kim Đồng",
            "isbn": "9786042163456",
            "price": 55000,
            "discount_price": 45000,
            "description": "Câu chuyện phiêu lưu đầy thú vị của chú Dế Mèn dũng cảm qua lăng kính loài vật sống động.",
            "stock": 60,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/a/a9/De_men_phieu_luu_ky.jpg",
            "is_best_selling": False
        },
        {
            "title": "Doraemon Tập 2",
            "author_name": "Fujiko F. Fujio",
            "category_name": "Truyện tranh",
            "publisher_name": "NXB Kim Đồng",
            "isbn": "9786042168403",
            "price": 25000,
            "discount_price": None,
            "description": "Cuộc phiêu lưu tiếp theo với Nobita cùng các bảo bối thần kỳ của chú mèo máy Doraemon.",
            "stock": 80,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/0/03/Doraemon2.jpg",
            "is_best_selling": False
        },
        {
            "title": "Doraemon Tập 3",
            "author_name": "Fujiko F. Fujio",
            "category_name": "Truyện tranh",
            "publisher_name": "NXB Kim Đồng",
            "isbn": "9786042168410",
            "price": 25000,
            "discount_price": None,
            "description": "Những mẩu truyện hài hước và ý nghĩa về tình bạn của nhóm Nobita, Shizuka, Jaian và Suneo.",
            "stock": 80,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/7/79/Doraemon3.jpg",
            "is_best_selling": False
        },
        {
            "title": "Doraemon Tập 4",
            "author_name": "Fujiko F. Fujio",
            "category_name": "Truyện tranh",
            "publisher_name": "NXB Kim Đồng",
            "isbn": "9786042168427",
            "price": 25000,
            "discount_price": None,
            "description": "Cuốn sách truyện tranh chứa đựng những bài học sâu sắc về cuộc sống thông qua những trò nghịch ngợm đáng yêu.",
            "stock": 85,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/e/ec/Doraemon4.jpg",
            "is_best_selling": False
        },
        {
            "title": "Harry Potter và Tên Tù Nhân Ngục Azkaban",
            "author_name": "J.K. Rowling",
            "category_name": "Sách thiếu nhi",
            "publisher_name": "NXB Trẻ",
            "isbn": "9786041132224",
            "price": 165000,
            "discount_price": 145000,
            "description": "Năm học thứ ba của Harry tại Hogwarts khi tên tù nhân Sirius Black trốn thoát khỏi Azkaban tìm kiếm cậu.",
            "stock": 25,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/f/f6/Harry_Potter_v%C3%A0_T%C3%AAn_t%C3%B9_nh%C3%A2n_ng%E1%BB%A5c_Azkaban.jpg",
            "is_best_selling": True
        },
        {
            "title": "Harry Potter và Chiếc Cốc Lửa",
            "author_name": "J.K. Rowling",
            "category_name": "Sách thiếu nhi",
            "publisher_name": "NXB Trẻ",
            "isbn": "9786041132225",
            "price": 220000,
            "discount_price": 189000,
            "description": "Harry vô tình bị chọn tham gia Giải đấu Tam Pháp Thuật đầy nguy hiểm và sự trở lại của Chúa tể Voldemort.",
            "stock": 20,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/c/c7/Harry_Potter_v%C3%A0_Chi%E1%BA%BFc_c%E1%BB%91c_l%E1%BB%ADa.jpg",
            "is_best_selling": True
        },
        {
            "title": "Harry Potter và Mệnh Lệnh Phượng Hoàng",
            "author_name": "J.K. Rowling",
            "category_name": "Sách thiếu nhi",
            "publisher_name": "NXB Trẻ",
            "isbn": "9786041132226",
            "price": 280000,
            "discount_price": 249000,
            "description": "Hội Phượng Hoàng tập hợp lực lượng chống lại Voldemort trong khi Bộ Pháp Thuật từ chối tin vào sự thật.",
            "stock": 18,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/9/9c/Harry_Potter_v%C3%A0_M%E1%BB%87nh_l%E1%BB%8nt_Ph%C6%B0%E1%BB%A3ng_ho%C3%A0ng.jpg",
            "is_best_selling": False
        },
        {
            "title": "Harry Potter và Hoàng Tử Lai",
            "author_name": "J.K. Rowling",
            "category_name": "Sách thiếu nhi",
            "publisher_name": "NXB Trẻ",
            "isbn": "9786041132227",
            "price": 240000,
            "discount_price": 215000,
            "description": "Harry tìm thấy một cuốn sách độc dược cũ thuộc về Hoàng tử Lai và bắt đầu học về quá khứ của Voldemort.",
            "stock": 15,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/d/d7/Harry_Potter_v%C3%A0_Ho%C3%A0ng_t%E1%BB%AD_lai.jpg",
            "is_best_selling": False
        },
        {
            "title": "Harry Potter và Bảo Bối Tử Thần",
            "author_name": "J.K. Rowling",
            "category_name": "Sách thiếu nhi",
            "publisher_name": "NXB Trẻ",
            "isbn": "9786041132228",
            "price": 310000,
            "discount_price": 279000,
            "description": "Tập cuối cùng của loạt truyện. Trận chiến quyết định tại Hogwarts nổ ra giữa lực lượng phù thủy tốt và Tử thần Thực tử.",
            "stock": 30,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/e/ee/Harry_Potter_v%C3%A0_B%E1%BA%A3o_b%E1%BB%91i_t%E1%BB%AD_th%E1%BA%A7n.jpg",
            "is_best_selling": True
        },
        {
            "title": "7 Thói Quen Để Thành Đạt",
            "author_name": "Stephen R. Covey",
            "category_name": "Kỹ năng sống",
            "publisher_name": "NXB Trẻ",
            "isbn": "9786041145612",
            "price": 140000,
            "discount_price": 119000,
            "description": "Cuốn sách thay đổi tư duy hiệu quả công việc và làm chủ bản thân, định hình lối sống thành công.",
            "stock": 45,
            "cover_image": "https://upload.wikimedia.org/wikipedia/en/a/a2/The_7_Habits_of_Highly_Effective_People.jpg",
            "is_best_selling": True
        },
        {
            "title": "Nghĩ Giàu Và Làm Giàu",
            "author_name": "Napoleon Hill",
            "category_name": "Kỹ năng sống",
            "publisher_name": "NXB Trẻ",
            "isbn": "9786041145613",
            "price": 110000,
            "discount_price": 95000,
            "description": "Một trong những cuốn sách bán chạy nhất mọi thời đại về kỹ năng tạo lập sự giàu có toàn diện.",
            "stock": 50,
            "cover_image": "https://upload.wikimedia.org/wikipedia/en/e/e9/Think_and_grow_rich_original_cover.jpg",
            "is_best_selling": True
        },
        {
            "title": "Cha Giàu Cha Nghèo",
            "author_name": "Robert Kiyosaki",
            "category_name": "Kinh tế",
            "publisher_name": "NXB Trẻ",
            "isbn": "9786041145614",
            "price": 120000,
            "discount_price": 99000,
            "description": "Cuốn sách định hướng tư duy tài chính cá nhân khác biệt giữa người giàu và người nghèo.",
            "stock": 55,
            "cover_image": "https://upload.wikimedia.org/wikipedia/en/b/b9/Rich_Dad_Poor_Dad.jpg",
            "is_best_selling": True
        },
        {
            "title": "Quốc Gia Khởi Nghiệp",
            "author_name": "Dan Senor",
            "category_name": "Kinh tế",
            "publisher_name": "NXB Thế Giới",
            "isbn": "9786047745615",
            "price": 135000,
            "discount_price": 115000,
            "description": "Câu chuyện thần kỳ về sự trỗi dậy của Israel - từ một quốc gia nhỏ bé thành thung lũng công nghệ sáng tạo.",
            "stock": 40,
            "cover_image": "https://upload.wikimedia.org/wikipedia/en/5/5b/Start-up_Nation.jpg",
            "is_best_selling": True
        },
        {
            "title": "Bắt Trẻ Đồng Xanh",
            "author_name": "J.D. Salinger",
            "category_name": "Văn học",
            "publisher_name": "NXB Hội Nhà Văn",
            "isbn": "9786049691122",
            "price": 85000,
            "discount_price": 69000,
            "description": "Cuốn tiểu thuyết kinh điển lột tả sự cô đơn và phản kháng nổi loạn của lứa tuổi vị thành niên.",
            "stock": 25,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/c/cb/The_Catcher_in_the_Rye.jpg",
            "is_best_selling": False
        },
        {
            "title": "Không Gia Đình",
            "author_name": "Hector Malot",
            "category_name": "Sách thiếu nhi",
            "publisher_name": "NXB Kim Đồng",
            "isbn": "9786042153213",
            "price": 115000,
            "discount_price": 95000,
            "description": "Cuộc đời thăng trầm vượt qua gian khó đầy tính nhân văn sâu sắc của cậu bé Remi mồ côi.",
            "stock": 35,
            "cover_image": "https://upload.wikimedia.org/wikipedia/vi/3/3f/Bia_sach_khong_gia_dinh_nxb_kim_dong.jpg",
            "is_best_selling": True
        },
        {
            "title": "Đại Số Tuyến Tính",
            "author_name": "Stephen R. Covey",
            "category_name": "Giáo dục",
            "publisher_name": "NXB Giáo Dục",
            "isbn": "9786040123456",
            "price": 65000,
            "discount_price": None,
            "description": "Giáo trình toán cao cấp đại số tuyến tính phục vụ học tập nghiên cứu khối ngành kỹ thuật.",
            "stock": 120,
            "cover_image": "https://images.unsplash.com/photo-1509228468518-180dd4864904?w=500",
            "is_best_selling": False
        },
        {
            "title": "Giải Tích 1",
            "author_name": "Stephen R. Covey",
            "category_name": "Giáo dục",
            "publisher_name": "NXB Giáo Dục",
            "isbn": "9786040123457",
            "price": 70000,
            "discount_price": None,
            "description": "Giáo trình toán giải tích căn bản về vi phân tích phân một biến số.",
            "stock": 130,
            "cover_image": "https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=500",
            "is_best_selling": False
        }
    ]

    for b_data in books_data:
        bk = db.query(models.Book).filter(models.Book.title == b_data["title"]).first()
        if not bk:
            bk = models.Book(
                title=b_data["title"],
                author_id=db_authors[b_data["author_name"]].id,
                category_id=db_categories[b_data["category_name"]].id,
                publisher_id=db_publishers[b_data["publisher_name"]].id,
                isbn=b_data["isbn"],
                price=b_data["price"],
                discount_price=b_data["discount_price"],
                description=b_data["description"],
                stock=b_data["stock"],
                cover_image=b_data["cover_image"],
                is_best_selling=b_data["is_best_selling"],
                rating=0.0
            )
            db.add(bk)
            db.commit()
            db.refresh(bk)
            print(f"Thêm sách -> {b_data['title']}")

    # 6. Seed Coupons
    coupons = [
        {"code": "GIAM10", "discount_value": 10.0, "type": models.CouponTypeEnum.percentage},
        {"code": "READING50K", "discount_value": 50000.0, "type": models.CouponTypeEnum.fixed}
    ]
    for cp_data in coupons:
        cp = db.query(models.Coupon).filter(models.Coupon.code == cp_data["code"]).first()
        if not cp:
            cp = models.Coupon(
                code=cp_data["code"],
                discount_value=cp_data["discount_value"],
                type=cp_data["type"],
                is_active=True
            )
            db.add(cp)
            print(f"Thêm mã giảm giá -> {cp_data['code']}")

    db.commit()

    # 7. Seed Reviews
    # Add some ratings & reviews for Mắt Biếc & Đắc Nhân Tâm
    mat_biec = db.query(models.Book).filter(models.Book.title == "Mắt Biếc").first()
    dac_nhan_tam = db.query(models.Book).filter(models.Book.title == "Đắc Nhân Tâm").first()
    buyer1 = db.query(models.User).filter(models.User.username == "user1").first()
    buyer2 = db.query(models.User).filter(models.User.username == "user2").first()

    if mat_biec and buyer1:
        if not db.query(models.Review).filter(models.Review.book_id == mat_biec.id, models.Review.user_id == buyer1.id).first():
            rev = models.Review(
                user_id=buyer1.id,
                book_id=mat_biec.id,
                rating=5,
                comment="Cuốn sách rất hay và đầy xúc cảm, Ngạn là nhân vật tôi thích nhất!"
            )
            db.add(rev)
    if mat_biec and buyer2:
        if not db.query(models.Review).filter(models.Review.book_id == mat_biec.id, models.Review.user_id == buyer2.id).first():
            rev = models.Review(
                user_id=buyer2.id,
                book_id=mat_biec.id,
                rating=4,
                comment="Một cái kết buồn nhưng rất trọn vẹn và nhiều dư âm."
            )
            db.add(rev)

    if dac_nhan_tam and buyer1:
        if not db.query(models.Review).filter(models.Review.book_id == dac_nhan_tam.id, models.Review.user_id == buyer1.id).first():
            rev = models.Review(
                user_id=buyer1.id,
                book_id=dac_nhan_tam.id,
                rating=5,
                comment="Cuốn sách thay đổi cuộc đời tôi. Rất đáng mua và gối đầu giường."
            )
            db.add(rev)

    db.commit()

    # Recalculate average ratings
    for book in db.query(models.Book).all():
        revs = db.query(models.Review).filter(models.Review.book_id == book.id).all()
        if revs:
            avg = sum([r.rating for r in revs]) / len(revs)
            book.rating = round(avg, 1)
        else:
            book.rating = 4.5 # Default rating for items without reviews
    db.commit()
    print("Khởi tạo và tính toán điểm đánh giá sách thành công!")

    print("=== HOÀN TẤT SEED DỮ LIỆU BÁN SÁCH ===")
finally:
    db.close()
