/// Single source of truth for every translated, user-facing string in the
/// app. Keys are short descriptive names (not the raw English text, since
/// that itself varies by language) -- looked up via ThemeProvider.t(key)
/// or the context.tr(key) extension, both of which fall back to English
/// for any key missing a translation in the current language.
class AppStrings {
  static const Map<String, Map<String, String>> _values = {
    // Settings screen
    'settings': {'English': 'Settings', 'Filipino': 'Mga Setting'},
    'preferences': {'English': 'Preferences', 'Filipino': 'Mga Kagustuhan'},
    'dark_mode': {'English': 'Dark Mode', 'Filipino': 'Madilim na Mode'},
    'dark_mode_enabled': {'English': 'Dark mode enabled', 'Filipino': 'Na-enable ang dark mode'},
    'dark_mode_disabled': {'English': 'Dark mode disabled', 'Filipino': 'Na-disable ang dark mode'},
    'notifications': {'English': 'Notifications', 'Filipino': 'Mga Abiso'},
    'notifications_enabled': {'English': 'Notifications enabled', 'Filipino': 'Na-enable ang mga abiso'},
    'notifications_disabled': {'English': 'Notifications disabled', 'Filipino': 'Na-disable ang mga abiso'},
    'about_section': {'English': 'About', 'Filipino': 'Tungkol Dito'},
    'privacy_policy': {'English': 'Privacy Policy', 'Filipino': 'Patakaran sa Privacy'},
    'terms_conditions': {'English': 'Terms & Conditions', 'Filipino': 'Mga Tuntunin at Kundisyon'},
    'about_herbai': {'English': 'About HERBAI', 'Filipino': 'Tungkol sa HERBAI'},
    'reset_settings': {'English': 'Reset Settings', 'Filipino': 'I-reset ang Settings'},
    'language': {'English': 'Language', 'Filipino': 'Wika'},
    'select_language': {'English': 'Select Language', 'Filipino': 'Pumili ng Wika'},
    'language_set_to': {'English': 'Language set to', 'Filipino': 'Naitakda ang wika sa'},
    'cancel': {'English': 'Cancel', 'Filipino': 'Kanselahin'},
    'reset': {'English': 'Reset', 'Filipino': 'I-reset'},
    'reset_settings_confirm': {
      'English': 'Are you sure you want to reset all settings to default?',
      'Filipino': 'Sigurado ka bang gusto mong i-reset ang lahat ng setting sa default?',
    },
    'settings_reset_success': {
      'English': 'Settings reset successfully',
      'Filipino': 'Matagumpay na na-reset ang mga setting',
    },

    // Home screen
    'welcome_to_herbai': {'English': 'Welcome to HERBAI', 'Filipino': 'Maligayang pagdating sa HERBAI'},
    'discover_herbal_medicine': {
      'English': 'Discover the power of herbal medicine',
      'Filipino': 'Tuklasin ang kapangyarihan ng halamang gamot',
    },
    'featured_plants': {'English': 'Featured Plants', 'Filipino': 'Mga Itinatampok na Halaman'},
    'no_plants_yet': {'English': 'No plants yet', 'Filipino': 'Wala pang halaman'},
    'your_recommendations': {'English': 'Your Recommendations', 'Filipino': 'Iyong mga Rekomendasyon'},
    'recently_viewed': {'English': 'Recently Viewed', 'Filipino': 'Kamakailang Tiningnan'},
    'no_recommendations_yet': {'English': 'No recommendations yet', 'Filipino': 'Wala pang rekomendasyon'},
    'start_now': {'English': 'Start Now', 'Filipino': 'Magsimula Na'},
    'describe_your_symptoms': {'English': 'Describe Your Symptoms', 'Filipino': 'Ilarawan ang Iyong mga Sintomas'},
    'type_how_you_feel': {
      'English': 'Type how you feel in your own words',
      'Filipino': 'I-type kung ano ang nararamdaman mo gamit ang sarili mong mga salita',
    },
    'browse_all_plants': {'English': 'Browse All Plants', 'Filipino': 'Tingnan ang Lahat ng Halaman'},
    'explore_plant_library': {
      'English': 'Explore our full herbal plant library',
      'Filipino': 'Galugarin ang aming kumpletong aklatan ng halamang gamot',
    },
    'start_herbal_recommendation': {
      'English': 'Start Herbal Recommendation',
      'Filipino': 'Simulan ang Rekomendasyon ng Halamang Gamot',
    },
    'select_symptoms_ai_blurb': {
      'English': "Select your symptoms and let HERBAI's AI recommend the most suitable medicinal plants.",
      'Filipino': 'Piliin ang iyong mga sintomas at hayaang irekomenda ng AI ng HERBAI ang pinakaangkop na halamang gamot.',
    },
    'start_recommendation': {'English': 'Start Recommendation', 'Filipino': 'Simulan ang Rekomendasyon'},

    // Login screen
    'welcome_back': {'English': 'Welcome Back', 'Filipino': 'Maligayang Pagbabalik'},
    'sign_in_to_continue': {'English': 'Sign in to continue', 'Filipino': 'Mag-sign in para magpatuloy'},
    'email_hint': {'English': 'Email', 'Filipino': 'Email'},
    'please_enter_email': {'English': 'Please enter your email', 'Filipino': 'Pakilagay ang iyong email'},
    'please_enter_valid_email': {'English': 'Please enter a valid email', 'Filipino': 'Pakilagay ang wastong email'},
    'password_hint': {'English': 'Password', 'Filipino': 'Password'},
    'please_enter_password': {'English': 'Please enter your password', 'Filipino': 'Pakilagay ang iyong password'},
    'remember_email_device': {
      'English': 'Remember my email on this device',
      'Filipino': 'Tandaan ang aking email sa device na ito',
    },
    'forgot_password_q': {'English': 'Forgot password?', 'Filipino': 'Nakalimutan ang password?'},
    'sign_in': {'English': 'Sign In', 'Filipino': 'Mag-sign In'},
    'no_account_q': {'English': "Don't have an account?", 'Filipino': 'Wala ka pang account?'},
    'sign_up': {'English': 'Sign up', 'Filipino': 'Mag-sign Up'},
    'too_many_attempts_prefix': {
      'English': 'Too many attempts. Try again in',
      'Filipino': 'Sobra na ang pagsubok. Subukan ulit sa loob ng',
    },
    'incorrect_email': {'English': 'Incorrect email.', 'Filipino': 'Maling email.'},
    'incorrect_password': {'English': 'Incorrect password.', 'Filipino': 'Maling password.'},

    // Register screen
    'account_created_verify': {
      'English': 'Account created. Please verify your email.',
      'Filipino': 'Nagawa na ang account. Pakiberipika ang iyong email.',
    },
    'create_account': {'English': 'Create Account', 'Filipino': 'Gumawa ng Account'},
    'create_simple_account': {
      'English': 'Create a simple account to get started',
      'Filipino': 'Gumawa ng simpleng account para makapagsimula',
    },
    'full_name_hint': {'English': 'Full Name', 'Filipino': 'Buong Pangalan'},
    'please_enter_name': {'English': 'Please enter your name', 'Filipino': 'Pakilagay ang iyong pangalan'},
    'email_already_registered': {
      'English': 'This email is already registered.',
      'Filipino': 'Ang email na ito ay rehistrado na.',
    },
    'checking_email': {'English': 'Checking email...', 'Filipino': 'Chine-check ang email...'},
    'password_min_length': {
      'English': 'Password must be at least 8 characters',
      'Filipino': 'Dapat hindi bababa sa 8 karakter ang password',
    },
    'password_needs_uppercase': {
      'English': 'Password must contain an uppercase letter',
      'Filipino': 'Dapat may malaking titik ang password',
    },
    'password_needs_lowercase': {
      'English': 'Password must contain a lowercase letter',
      'Filipino': 'Dapat may maliit na titik ang password',
    },
    'password_needs_number': {
      'English': 'Password must contain a number',
      'Filipino': 'Dapat may numero ang password',
    },
    'password_needs_special': {
      'English': 'Password must contain a special character',
      'Filipino': 'Dapat may espesyal na karakter ang password',
    },
    'req_8_characters': {'English': '8+ characters', 'Filipino': '8+ na karakter'},
    'req_uppercase': {'English': 'Uppercase letter', 'Filipino': 'Malaking titik'},
    'req_lowercase': {'English': 'Lowercase letter', 'Filipino': 'Maliit na titik'},
    'req_number': {'English': 'Number', 'Filipino': 'Numero'},
    'req_special_char': {'English': 'Special character', 'Filipino': 'Espesyal na karakter'},
    'confirm_password_hint': {'English': 'Confirm Password', 'Filipino': 'Kumpirmahin ang Password'},
    'please_confirm_password': {
      'English': 'Please confirm your password',
      'Filipino': 'Pakikumpirma ang iyong password',
    },
    'passwords_do_not_match': {
      'English': 'Passwords do not match',
      'Filipino': 'Hindi magkatugma ang mga password',
    },
    'passwords_match': {'English': 'Passwords match', 'Filipino': 'Magkatugma ang mga password'},
    'already_have_account_q': {'English': 'Already have an account? ', 'Filipino': 'May account ka na? '},

    // Forgot password screen
    'no_account_for_email': {
      'English': 'No account found for that email.',
      'Filipino': 'Walang nahanap na account para sa email na iyon.',
    },
    'reset_password': {'English': 'Reset Password', 'Filipino': 'I-reset ang Password'},
    'enter_email_reset_blurb': {
      'English': "Enter your email and we'll send you a link to reset your password.",
      'Filipino': 'Ilagay ang iyong email at magpapadala kami ng link para i-reset ang iyong password.',
    },
    'send_reset_link': {'English': 'Send reset link', 'Filipino': 'Ipadala ang reset link'},
    'back_to_login': {'English': 'Back to login', 'Filipino': 'Bumalik sa login'},

    // Email verification screen
    'verification_code_sent': {
      'English': 'Verification code sent. Please check your inbox.',
      'Filipino': 'Naipadala na ang verification code. Pakitingnan ang iyong inbox.',
    },
    'could_not_send_code': {
      'English': 'Could not send the code. Please try again.',
      'Filipino': 'Hindi maipadala ang code. Pakisubukan muli.',
    },
    'enter_6_digit_code': {
      'English': 'Enter the 6-digit code from your email.',
      'Filipino': 'Ilagay ang 6-digit na code mula sa iyong email.',
    },
    'not_signed_in': {'English': 'Not signed in.', 'Filipino': 'Hindi naka-sign in.'},
    'verify_your_email': {'English': 'Verify your email', 'Filipino': 'I-verify ang iyong email'},
    'we_sent_6_digit_code_to': {
      'English': 'We sent a 6-digit code to',
      'Filipino': 'Nagpadala kami ng 6-digit na code sa',
    },
    'your_email_fallback': {'English': 'your email', 'Filipino': 'iyong email'},
    'verifying': {'English': 'Verifying...', 'Filipino': 'Vine-verify...'},
    'verify': {'English': 'Verify', 'Filipino': 'I-verify'},
    'sending': {'English': 'Sending...', 'Filipino': 'Ipinapadala...'},
    'resend_code': {'English': 'Resend code', 'Filipino': 'Ipadala Muli ang Code'},
    'sign_out': {'English': 'Sign out', 'Filipino': 'Mag-sign Out'},

    // Reset password success screen
    'email_sent_exclaim': {'English': 'Email Sent!', 'Filipino': 'Naipadala na ang Email!'},
    'password_reset_sent_blurb': {
      'English': 'Password reset email has been sent.\nPlease check your Gmail.',
      'Filipino': 'Naipadala na ang email para sa pag-reset ng password.\nPakitingnan ang iyong Gmail.',
    },
    'back_to_sign_in': {'English': 'Back to Sign In', 'Filipino': 'Bumalik sa Sign In'},

    // Profile screen
    'logout': {'English': 'Logout', 'Filipino': 'Mag-logout'},
    'logout_confirm': {
      'English': 'Are you sure you want to logout?',
      'Filipino': 'Sigurado ka bang gusto mong mag-logout?',
    },
    'profile': {'English': 'Profile', 'Filipino': 'Profile'},
    'herbal_enthusiast': {'English': 'Herbal Enthusiast', 'Filipino': 'Mahilig sa Halamang Gamot'},
    'favorites': {'English': 'Favorites', 'Filipino': 'Mga Paborito'},
    'reviews': {'English': 'Reviews', 'Filipino': 'Mga Review'},
    'searches': {'English': 'Searches', 'Filipino': 'Mga Paghahanap'},
    'edit_profile': {'English': 'Edit Profile', 'Filipino': 'I-edit ang Profile'},

    // Edit profile screen
    'could_not_save_changes': {
      'English': 'Could not save your changes. Please try again.',
      'Filipino': 'Hindi na-save ang iyong mga pagbabago. Pakisubukan muli.',
    },
    'display_name_hint': {'English': 'Display Name', 'Filipino': 'Ipakitang Pangalan'},
    'save_changes': {'English': 'Save Changes', 'Filipino': 'I-save ang mga Pagbabago'},

    // About screen
    'about_herbai_title': {'English': 'About HERBAI', 'Filipino': 'Tungkol sa HERBAI'},
    'version_1_0_0': {'English': 'Version 1.0.0', 'Filipino': 'Bersyon 1.0.0'},
    'developer_team': {
      'English': 'Developer: Herbal Research Team',
      'Filipino': 'Taga-develop: Herbal Research Team',
    },
    'research_title_label': {'English': 'Research Title', 'Filipino': 'Pamagat ng Pananaliksik'},
    'research_title_value': {
      'English': 'AI-Driven Integration of Ethnobotanical Knowledge: A Mobile System for Local Herbal Plant Recommendations',
      'Filipino': 'AI-Driven Integration of Ethnobotanical Knowledge: A Mobile System for Local Herbal Plant Recommendations',
    },
    'app_description_label': {'English': 'App Description', 'Filipino': 'Paglalarawan ng App'},
    'app_description_value': {
      'English': 'HERBAI is a modern healthcare application that preserves and promotes ethnobotanical herbal knowledge. The application allows users to explore herbal plants, search medicinal information, save favorite plants, and prepares for future AI-powered herbal recommendations and plant image identification.',
      'Filipino': 'Ang HERBAI ay isang modernong aplikasyon sa pangangalagang pangkalusugan na nagpapanatili at nagtataguyod ng kaalaman sa etnobotanikal na halamang gamot. Hinahayaan ng application ang mga user na mag-explore ng mga halamang gamot, maghanap ng impormasyong medisinal, i-save ang mga paboritong halaman, at ihanda ang sarili para sa hinaharap na AI-powered na mga rekomendasyon ng halamang gamot at pagkilala sa larawan ng halaman.',
    },
    'our_mission_label': {'English': 'Our Mission', 'Filipino': 'Aming Misyon'},
    'our_mission_value': {
      'English': 'To bridge the gap between traditional herbal knowledge and modern technology, making natural remedies accessible, reliable, and easy to discover for everyone worldwide.',
      'Filipino': 'Upang tugunan ang puwang sa pagitan ng tradisyunal na kaalaman sa halamang gamot at modernong teknolohiya, ginagawang naa-access, maaasahan, at madaling matuklasan ang natural na lunas para sa lahat sa buong mundo.',
    },
    'our_vision_label': {'English': 'Our Vision', 'Filipino': 'Aming Bisyon'},
    'our_vision_value': {
      'English': 'A world where traditional herbal wisdom is preserved, respected, and integrated with modern healthcare practices for the benefit of all.',
      'Filipino': 'Isang mundo kung saan ang tradisyunal na karunungan sa halamang gamot ay napapanatili, iginagalang, at isinasama sa modernong gawi sa pangangalagang pangkalusugan para sa kapakinabangan ng lahat.',
    },
    'research_development_label': {'English': 'Research & Development', 'Filipino': 'Pananaliksik at Pag-unlad'},
    'research_development_value': {
      'English': 'Our team works closely with botanists, traditional healers, and researchers to ensure accurate and reliable information. Future updates will include AI-powered recommendations and plant identification.',
      'Filipino': 'Ang aming team ay malapit na nakikipagtulungan sa mga botanist, tradisyunal na manggagamot, at mananaliksik upang matiyak ang tumpak at maaasahang impormasyon. Ang mga susunod na update ay magsasama ng AI-powered na mga rekomendasyon at pagkilala sa halaman.',
    },
    'copyright_herbai': {
      'English': '© 2026 HERBAI. All rights reserved.',
      'Filipino': '© 2026 HERBAI. Nakalaan ang lahat ng karapatan.',
    },

    // Privacy policy screen
    'last_updated_july_2026': {'English': 'Last Updated: July 2026', 'Filipino': 'Huling Na-update: Hulyo 2026'},
    'pp_section_1_title': {'English': '1. Data Collection', 'Filipino': '1. Pagkolekta ng Data'},
    'pp_section_1_body': {
      'English': 'HERBAI is designed to prioritize your privacy. Currently, the application operates entirely locally on your device and does not collect any personal data, user information, or usage statistics. All data, including your favorite plants, settings, and search history, is stored locally on your device using SharedPreferences.',
      'Filipino': 'Ang HERBAI ay dinisenyo upang unahin ang iyong privacy. Sa ngayon, gumagana ang application nang ganap na lokal sa iyong device at hindi kumokolekta ng anumang personal na data, impormasyon ng user, o usage statistics. Ang lahat ng data, kasama ang iyong mga paboritong halaman, setting, at kasaysayan ng paghahanap, ay naka-imbak nang lokal sa iyong device gamit ang SharedPreferences.',
    },
    'pp_section_2_title': {'English': '2. User Privacy', 'Filipino': '2. Privacy ng User'},
    'pp_section_2_body': {
      'English': 'We are committed to protecting your privacy. Since no data is collected from your device, there is no risk of your personal information being shared, sold, or accessed by third parties. Your herbal plant preferences and usage remain completely private and confidential.',
      'Filipino': 'Kami ay nakatuon sa pagprotekta sa iyong privacy. Dahil walang data na kinokolekta mula sa iyong device, walang panganib na mas-share, maibenta, o ma-access ng ibang partido ang iyong personal na impormasyon. Ang iyong mga kagustuhan at paggamit ng halamang gamot ay nananatiling ganap na pribado at kumpidensyal.',
    },
    'pp_section_3_title': {'English': '3. Local Storage', 'Filipino': '3. Lokal na Imbakan'},
    'pp_section_3_body': {
      'English': 'All application data is stored locally on your mobile device. This includes:\n• Theme preferences (light/dark mode)\n• Notification settings\n• Language selection\n• Favorite plants\n• Recent searches\n\nYou can clear this data at any time by resetting your settings within the application or by uninstalling the app.',
      'Filipino': 'Ang lahat ng data ng application ay naka-imbak nang lokal sa iyong mobile device. Kasama dito:\n• Mga kagustuhan sa theme (light/dark mode)\n• Mga setting ng notification\n• Pagpili ng wika\n• Mga paboritong halaman\n• Kamakailang paghahanap\n\nMaaari mong burahin ang data na ito anumang oras sa pamamagitan ng pag-reset ng iyong mga setting sa loob ng application o sa pag-uninstall ng app.',
    },
    'pp_section_4_title': {'English': '4. Future AI Features', 'Filipino': '4. Mga Hinaharap na Feature ng AI'},
    'pp_section_4_body': {
      'English': 'Future versions of HERBAI may include AI-driven features such as plant identification and personalized recommendations. These features will be optional, and we will update this privacy policy accordingly before implementing any changes that involve data collection or processing outside of your device.',
      'Filipino': 'Ang mga susunod na bersyon ng HERBAI ay maaaring may kasamang mga feature na pinapagana ng AI tulad ng pagkilala sa halaman at personalisadong rekomendasyon. Ang mga feature na ito ay magiging optional, at ia-update namin ang patakarang ito sa privacy bago ipatupad ang anumang pagbabagong may kinalaman sa pagkolekta o pagproseso ng data sa labas ng iyong device.',
    },
    'pp_section_5_title': {'English': '5. Contact Information', 'Filipino': '5. Impormasyon sa Pakikipag-ugnayan'},
    'pp_section_5_body': {
      'English': 'If you have any questions or concerns about this privacy policy or the HERBAI application, please contact us at:\n\nEmail: privacy@herbai.app\nAddress: Herbal Research Institute, Cebu, Philippines',
      'Filipino': 'Kung mayroon kang anumang katanungan o alalahanin tungkol sa patakarang ito sa privacy o sa HERBAI application, makipag-ugnayan sa amin sa:\n\nEmail: privacy@herbai.app\nAddress: Herbal Research Institute, Cebu, Philippines',
    },

    // Terms and conditions screen
    'terms_and_conditions_full': {'English': 'Terms and Conditions', 'Filipino': 'Mga Tuntunin at Kundisyon'},
    'tc_section_1_title': {'English': '1. User Responsibilities', 'Filipino': '1. Pananagutan ng User'},
    'tc_section_1_body': {
      'English': 'By using the HERBAI application, you agree to use it responsibly and for educational purposes only. The information provided in this app is based on ethnobotanical knowledge and should not replace professional medical advice.',
      'Filipino': 'Sa paggamit ng HERBAI application, sumasang-ayon kang gamitin ito nang responsable at para sa layuning pang-edukasyon lamang. Ang impormasyong ibinigay sa app na ito ay batay sa kaalaman sa etnobotanikal at hindi dapat palitan ang propesyonal na payo medikal.',
    },
    'tc_section_2_title': {'English': '2. Acceptable Use', 'Filipino': '2. Katanggap-tanggap na Paggamit'},
    'tc_section_2_body': {
      'English': 'You agree to:\n• Use the app for personal, non-commercial purposes only\n• Not misuse or attempt to reverse-engineer the application\n• Respect intellectual property rights of the developers and researchers\n• Not use the app for any illegal or unauthorized purpose',
      'Filipino': 'Sumasang-ayon kang:\n• Gamitin ang app para sa personal, hindi pangkomersyal na layunin lamang\n• Huwag abusuhin o subukang i-reverse-engineer ang application\n• Igalang ang mga karapatan sa intellectual property ng mga developer at mananaliksik\n• Huwag gamitin ang app para sa anumang ilegal o hindi awtorisadong layunin',
    },
    'tc_section_3_title': {'English': '3. Medical Disclaimer', 'Filipino': '3. Paunawang Medikal'},
    'tc_section_3_body': {
      'English': 'THE INFORMATION PROVIDED BY HERBAI IS FOR GENERAL EDUCATIONAL PURPOSES ONLY. IT IS NOT INTENDED TO BE A SUBSTITUTE FOR PROFESSIONAL MEDICAL ADVICE, DIAGNOSIS, OR TREATMENT. ALWAYS SEEK THE ADVICE OF YOUR PHYSICIAN OR OTHER QUALIFIED HEALTH PROVIDER WITH ANY QUESTIONS YOU MAY HAVE REGARDING A MEDICAL CONDITION.',
      'Filipino': 'ANG IMPORMASYONG IBINIGAY NG HERBAI AY PARA SA PANGKALAHATANG LAYUNING PANG-EDUKASYON LAMANG. HINDI ITO INILAAN BILANG KAPALIT NG PROPESYONAL NA PAYO MEDIKAL, DIYAGNOSIS, O PAGGAMOT. LAGING HUMINGI NG PAYO MULA SA IYONG DOKTOR O IBANG KWALIPIKADONG TAGAPAGLAAN NG KALUSUGAN PARA SA ANUMANG TANONG TUNGKOL SA KALAGAYANG MEDIKAL.',
    },
    'tc_section_4_title': {'English': '4. Limitation of Liability', 'Filipino': '4. Limitasyon ng Pananagutan'},
    'tc_section_4_body': {
      'English': 'IN NO EVENT SHALL THE DEVELOPERS, RESEARCHERS, OR AFFILIATES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES ARISING OUT OF OR IN ANY WAY CONNECTED WITH THE USE OF THIS APPLICATION.',
      'Filipino': 'SA ANUMANG PAGKAKATAON, HINDI MANANAGOT ANG MGA DEVELOPER, MANANALIKSIK, O KAANIB PARA SA ANUMANG DIREKTA, HINDI DIREKTA, INSIDENTAL, ESPESYAL, O KAAKIBAT NA PINSALA NA NAGMUMULA SA O SA ANUMANG PARAAN NA KONEKTADO SA PAGGAMIT NG APPLICATION NA ITO.',
    },
    'tc_section_5_title': {'English': '5. Future Updates', 'Filipino': '5. Mga Susunod na Update'},
    'tc_section_5_body': {
      'English': 'We reserve the right to modify or update these terms and conditions at any time. Continued use of the application after changes are posted constitutes your acceptance of the revised terms.',
      'Filipino': 'Nakalaan sa amin ang karapatang baguhin o i-update ang mga tuntunin at kundisyong ito anumang oras. Ang patuloy na paggamit ng application matapos mailathala ang mga pagbabago ay nangangahulugan ng iyong pagtanggap sa mga binagong tuntunin.',
    },

    // Symptom selection screen
    'select_your_symptoms': {'English': 'Select Your Symptoms', 'Filipino': 'Piliin ang Iyong mga Sintomas'},
    'what_symptoms_experiencing': {
      'English': 'What symptoms are you experiencing?',
      'Filipino': 'Anong mga sintomas ang nararanasan mo?',
    },
    'choose_all_symptoms': {
      'English': 'Choose all symptoms you are currently experiencing',
      'Filipino': 'Piliin ang lahat ng sintomas na kasalukuyan mong nararanasan',
    },
    'search_symptoms_hint': {'English': 'Search symptoms...', 'Filipino': 'Maghanap ng sintomas...'},
    'selected_symptoms': {'English': 'Selected Symptoms', 'Filipino': 'Mga Napiling Sintomas'},
    'search_results': {'English': 'Search Results', 'Filipino': 'Resulta ng Paghahanap'},
    'no_symptoms_found': {'English': 'No symptoms found', 'Filipino': 'Walang nahanap na sintomas'},
    'try_adjusting_search': {
      'English': 'Try adjusting your search terms',
      'Filipino': 'Subukang baguhin ang iyong mga salitang hinahanap',
    },
    'continue_label': {'English': 'Continue', 'Filipino': 'Magpatuloy'},

    // Describe symptoms screen
    'how_are_you_feeling': {'English': 'How are you feeling?', 'Filipino': 'Kumusta ang pakiramdam mo?'},
    'describe_symptoms_multilang_blurb': {
      'English': 'Describe your symptoms in English, Bisaya, or Tagalog. '
          'We will pick the matching symptoms for you.',
      'Filipino': 'Ilarawan ang iyong mga sintomas sa Ingles, Bisaya, o Tagalog. '
          'Pipiliin namin ang mga tumutugmang sintomas para sa iyo.',
    },
    'describe_symptoms_example_hint': {
      'English': 'e.g. "headache and fever" or "sakit akong ulo"',
      'Filipino': 'e.g. "headache and fever" or "sakit akong ulo"',
    },
    'detect_symptoms_tooltip': {'English': 'Detect symptoms', 'Filipino': 'Tukuyin ang mga sintomas'},
    'did_you_mean': {'English': 'Did you mean', 'Filipino': 'Ibig mo bang sabihin'},
    'instead_of': {'English': 'instead of', 'Filipino': 'sa halip na'},
    'please_correct_spelling': {
      'English': 'Please correct your spelling.',
      'Filipino': 'Pakiwasto ang iyong spelling.',
    },
    'no_matching_symptom': {
      'English': 'No matching symptom found. Try rephrasing or check spelling.',
      'Filipino': 'Walang nahanap na tumutugmang sintomas. Subukang baguhin ang pagkakasabi o tingnan ang spelling.',
    },
    'found_symptoms_prefix': {'English': 'Found', 'Filipino': 'Nakahanap ng'},
    'found_symptoms_suffix': {
      'English': 'symptom(s) from your description.',
      'Filipino': 'sintomas mula sa iyong paglalarawan.',
    },
    'detected_symptoms_tap_remove': {
      'English': 'Detected symptoms (tap x to remove)',
      'Filipino': 'Nakitang mga sintomas (i-tap ang x para tanggalin)',
    },
    'get_recommendations': {'English': 'Get Recommendations', 'Filipino': 'Kumuha ng mga Rekomendasyon'},

    // Health check screen
    'before_we_recommend': {'English': 'Before We Recommend', 'Filipino': 'Bago Kami Magrekomenda'},
    'does_any_apply': {
      'English': 'Does any of this apply right now?',
      'Filipino': 'May alinman ba dito na nalalapat sa iyo ngayon?',
    },
    'health_conditions_blurb': {
      'English': 'Some herbs carry extra precautions for these. '
          'Select any that apply so we can flag them for you.',
      'Filipino': 'May ilang halamang gamot na may karagdagang babala para dito. '
          'Piliin ang anumang nalalapat para ma-flag namin ito para sa iyo.',
    },
    // Keyed by Symptom.id from AppConstants.healthConditions, not by name,
    // since that list's `name` field itself can't be a translated getter
    // while staying a const list.
    'pregnant': {'English': 'Pregnant', 'Filipino': 'Buntis'},
    'breastfeeding': {'English': 'Breastfeeding', 'Filipino': 'Nagpapasuso'},
    'child': {'English': 'For a Child / Infant', 'Filipino': 'Para sa Bata / Sanggol'},

    // Recommendation screen
    'suggested_herbal_plants': {
      'English': 'Suggested Herbal Plants',
      'Filipino': 'Mga Iminumungkahing Halamang Gamot',
    },
    'suggested_plants_based_on_symptoms': {
      'English': '🌿 Suggested Herbal Plants Based on Your Selected Symptoms',
      'Filipino': '🌿 Mga Iminumungkahing Halamang Gamot Batay sa Iyong mga Napiling Sintomas',
    },
    'your_selected_symptoms_colon': {
      'English': 'Your Selected Symptoms:',
      'Filipino': 'Ang Iyong mga Napiling Sintomas:',
    },
    'sort_by': {'English': 'Sort By:', 'Filipino': 'Ayusin Ayon sa:'},
    'sort_best_match': {'English': 'Best Match', 'Filipino': 'Pinakaangkop'},
    'sort_highest_rated': {'English': 'Highest Rated', 'Filipino': 'Pinakamataas ang Rating'},
    'sort_alphabetical': {'English': 'Alphabetical', 'Filipino': 'Alpabetikal'},
    'no_plants_for_symptoms': {
      'English': 'No herbal plants were found for the selected symptoms.',
      'Filipino': 'Walang nahanap na halamang gamot para sa mga napiling sintomas.',
    },
    'choose_different_symptoms': {
      'English': 'Choose Different Symptoms',
      'Filipino': 'Pumili ng Ibang Sintomas',
    },
    'something_went_wrong': {'English': 'Something went wrong.', 'Filipino': 'May nangyaring mali.'},
    'check_connection_retry': {
      'English': 'Check your connection and try again.',
      'Filipino': 'Tingnan ang iyong koneksyon at subukang muli.',
    },
    'retry': {'English': 'Retry', 'Filipino': 'Subukang Muli'},
    'educational_purpose_only': {
      'English': 'Educational Purpose Only',
      'Filipino': 'Para sa Layuning Pang-edukasyon Lamang',
    },
    'herbai_educational_disclaimer': {
      'English': 'HERBAI provides educational information based on ethnobotanical knowledge. This application does not replace professional medical advice. Consult a licensed healthcare professional for proper diagnosis and treatment.',
      'Filipino': 'Nagbibigay ang HERBAI ng impormasyong pang-edukasyon batay sa kaalaman sa etnobotanikal. Hindi pinapalitan ng application na ito ang propesyonal na payo medikal. Kumunsulta sa lisensyadong propesyonal sa kalusugan para sa tamang diyagnosis at paggamot.',
    },

    // Splash screen
    'tagline': {
      'English': 'Smart Herbal Knowledge at Your Fingertips',
      'Filipino': 'Matalinong Kaalaman sa Halamang Gamot sa Iyong Kamay',
    },
    'welcome_shout': {'English': 'WELCOME', 'Filipino': 'MALIGAYANG PAGDATING'},
    'log_in_shout': {'English': 'LOG IN', 'Filipino': 'MAG-LOG IN'},
    'sign_up_shout': {'English': 'SIGN UP', 'Filipino': 'MAG-SIGN UP'},

    // Favorites screen
    'no_favorites_yet': {'English': 'No Favorites Yet', 'Filipino': 'Wala Pang Paborito'},
    'start_adding_favorites': {
      'English': 'Start adding your favorite herbal plants',
      'Filipino': 'Magsimulang magdagdag ng iyong mga paboritong halamang gamot',
    },

    // Main dashboard (bottom nav)
    'nav_home': {'English': 'Home', 'Filipino': 'Home'},
    'nav_recommendations': {'English': 'Recommendations', 'Filipino': 'Mga Rekomendasyon'},

    // Plant details screen
    'medicinal_uses': {'English': 'Medicinal Uses', 'Filipino': 'Mga Paggamit Medisinal'},
    'preparation_methods': {'English': 'Preparation Methods', 'Filipino': 'Paraan ng Paghahanda'},
    'safety_warnings': {'English': 'Safety Warnings', 'Filipino': 'Mga Babala sa Kaligtasan'},
    'source_label': {'English': 'Source', 'Filipino': 'Pinagmulan'},
    'description_label': {'English': 'Description', 'Filipino': 'Paglalarawan'},
    'relevant_to_you': {'English': 'Relevant to You', 'Filipino': 'Mahalaga Para Sa Iyo'},
    'traditional_knowledge': {'English': 'Traditional Knowledge', 'Filipino': 'Tradisyunal na Kaalaman'},
    'view_source': {'English': 'View source', 'Filipino': 'Tingnan ang pinagmulan'},
    'shared_via_herbai': {'English': 'Shared via HERBAI', 'Filipino': 'Ibinahagi sa pamamagitan ng HERBAI'},

    // Search screen
    'no_recent_searches': {'English': 'No Recent Searches', 'Filipino': 'Walang Kamakailang Paghahanap'},
    'start_searching_blurb': {
      'English': 'Start searching for herbal plants and remedies',
      'Filipino': 'Magsimulang maghanap ng halamang gamot at lunas',
    },
    'recent_searches': {'English': 'Recent Searches', 'Filipino': 'Mga Kamakailang Paghahanap'},
    'clear': {'English': 'Clear', 'Filipino': 'I-clear'},
    'popular_searches': {'English': 'Popular Searches', 'Filipino': 'Mga Sikat na Paghahanap'},
    'no_results_found': {'English': 'No Results Found', 'Filipino': 'Walang Nahanap na Resulta'},
    'try_different_keywords': {
      'English': 'Try searching with different keywords',
      'Filipino': 'Subukang maghanap gamit ang ibang keyword',
    },

    // Educational disclaimer dialog
    'educational_use_notice': {
      'English': 'Educational Use Notice',
      'Filipino': 'Paunawa sa Paggamit Pang-edukasyon',
    },
    'educational_disclaimer_body': {
      'English': 'HERBAI is developed strictly for educational and research '
          'purposes as a Capstone Project by students of Caraga State '
          'University – Cabadbaran Campus (CSUCC).\n\n'
          'The herbal recommendations and information provided are '
          'based on gathered ethnobotanical knowledge and an AI model '
          'still under development. They are not a substitute for '
          'professional medical advice, diagnosis, or treatment. '
          'Always consult a licensed healthcare professional before '
          'using any herbal remedy.\n\n'
          'This project is intended for further development and '
          'deployment under the Forestry Program of Caraga State '
          'University – Main Campus.\n\n'
          'By tapping "I Understand & Accept," you acknowledge that '
          'you are using this app for educational purposes only.',
      'Filipino': 'Ang HERBAI ay binuo nang mahigpit para sa layuning pang-edukasyon at '
          'pananaliksik bilang isang Capstone Project ng mga estudyante ng Caraga State '
          'University – Cabadbaran Campus (CSUCC).\n\n'
          'Ang mga rekomendasyon at impormasyong pang-halamang gamot na ibinigay ay '
          'batay sa nakalap na kaalaman sa etnobotanikal at isang AI model na nasa '
          'ilalim pa rin ng development. Hindi ito kapalit ng propesyonal na payo '
          'medikal, diyagnosis, o paggamot. Laging kumunsulta sa lisensyadong '
          'propesyonal sa kalusugan bago gumamit ng anumang lunas na halamang gamot.\n\n'
          'Ang proyektong ito ay inilaan para sa karagdagang development at deployment '
          'sa ilalim ng Forestry Program ng Caraga State University – Main Campus.\n\n'
          'Sa pag-tap ng "Nauunawaan Ko at Tinatanggap," kinikilala mong ginagamit mo '
          'ang app na ito para sa layuning pang-edukasyon lamang.',
    },
    'i_understand_accept': {
      'English': 'I Understand & Accept',
      'Filipino': 'Nauunawaan Ko at Tinatanggap',
    },

    // Plant rating section / rate plant modal
    'rating_singular': {'English': 'rating', 'Filipino': 'rating'},
    'rating_plural': {'English': 'ratings', 'Filipino': 'rating'},
    'edit_review': {'English': 'Edit Review', 'Filipino': 'I-edit ang Review'},
    'rate_and_review': {'English': 'Rate & Review', 'Filipino': 'Mag-rate at Mag-review'},
    'no_reviews_yet': {
      'English': 'No reviews yet — be the first to review this plant!',
      'Filipino': 'Wala pang review — maging una kang mag-review sa halamang ito!',
    },
    'sign_in_to_rate': {
      'English': 'Sign in to rate this plant.',
      'Filipino': 'Mag-sign in para mag-rate sa halamang ito.',
    },
    'tap_star_first': {
      'English': 'Tap a star to choose a rating first.',
      'Filipino': 'I-tap ang bituin para pumili muna ng rating.',
    },
    'could_not_save_rating': {
      'English': 'Could not save your rating. Please try again.',
      'Filipino': 'Hindi ma-save ang iyong rating. Pakisubukang muli.',
    },
    'rate_this_plant': {'English': 'Rate this plant', 'Filipino': 'I-rate ang halamang ito'},
    'share_experience_optional': {
      'English': 'Share your experience with this plant (optional)',
      'Filipino': 'Ibahagi ang iyong karanasan sa halamang ito (opsyonal)',
    },
    'post_review': {'English': 'Post Review', 'Filipino': 'I-post ang Review'},

    // Recommendation card
    'view_details': {'English': 'View Details', 'Filipino': 'Tingnan ang Detalye'},
    'may_help_with': {'English': 'May Help With:', 'Filipino': 'Maaaring Makatulong sa:'},

    // Source webview screen
    'source': {'English': 'Source', 'Filipino': 'Pinagmulan'},
  };

  static String t(String key, String language) =>
      _values[key]?[language] ?? _values[key]?['English'] ?? key;
}
