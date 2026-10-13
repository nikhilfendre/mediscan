/// Patient-education information for the 7 conditions the model can
/// predict. Written in plain language for the screening report.
///
/// IMPORTANT: this is general information only. It is not a diagnosis
/// and it never prescribes a medicine — treatment decisions are made
/// by a dermatologist after examination (and a biopsy where needed).
/// Strings are kept ASCII-only so they render identically on screen
/// and in the PDF (whose built-in font lacks some Unicode glyphs).
class DiseaseInfo {
  /// What the condition is, in simple words.
  final String about;

  /// Why it happens — causes and risk factors.
  final String causes;

  /// What the patient should do — care and precautions.
  final List<String> care;

  /// How the condition is usually managed — options a dermatologist
  /// may consider after examination. Never a prescription.
  final String treatment;

  const DiseaseInfo({
    required this.about,
    required this.causes,
    required this.care,
    required this.treatment,
  });

  static const Map<String, DiseaseInfo> _byLabel = {
    'Melanoma': DiseaseInfo(
      about:
          'Melanoma is a serious type of skin cancer that starts in the '
          'pigment-producing cells of the skin (melanocytes). It can grow '
          'and spread to other parts of the body if it is not found '
          'early, but when it is caught early it is usually curable.',
      causes:
          'The main risk factor is ultraviolet (UV) radiation from '
          'sunlight and tanning beds. Risk is higher with fair skin, '
          'many moles or unusual moles, a family history of melanoma, '
          'sunburns, and a weakened immune system.',
      care: [
        'See a dermatologist promptly - do not wait for months.',
        'Do not scratch, cut, squeeze or apply home remedies on it.',
        'Watch for the ABCDE signs: Asymmetry, irregular Border, '
            'multiple Colours, Diameter over 6 mm, Evolving (changing).',
        'Protect the area from sun exposure until you are examined.',
      ],
      treatment:
          'There is no self-medication for melanoma. A dermatologist '
          'confirms the diagnosis with a biopsy, and treatment usually '
          'involves surgical removal; any further treatment depends on '
          'the stage and is planned by specialists.',
    ),
    'Basal cell carcinoma': DiseaseInfo(
      about:
          'Basal cell carcinoma is the most common type of skin cancer. '
          'It grows slowly and very rarely spreads to other parts of '
          'the body, but it can damage the skin around it if untreated.',
      causes:
          'It is caused mainly by long-term sun (UV) exposure over many '
          'years. Fair skin, older age, and a previous skin cancer '
          'increase the risk.',
      care: [
        'Book a dermatologist appointment for examination.',
        'Do not pick at it or try to remove it yourself.',
        'Keep the area protected from sunlight.',
        'Note if it grows, bleeds, or does not heal - tell the doctor.',
      ],
      treatment:
          'The doctor confirms it with a biopsy. Depending on the size '
          'and location, treatment may include surgical removal or '
          'other procedures the dermatologist considers suitable. '
          'Medicines are used only when a doctor prescribes them after '
          'examination.',
    ),
    'Actinic keratosis': DiseaseInfo(
      about:
          'Actinic keratosis is a rough, scaly patch that develops on '
          'sun-damaged skin. It is considered a pre-cancerous change: '
          'most stay harmless, but a small number can turn into a type '
          'of skin cancer, so it should be checked.',
      causes:
          'It is caused by many years of cumulative sun (UV) exposure. '
          'It is more common in older people, fair-skinned people, and '
          'people who work outdoors.',
      care: [
        'Get it examined by a dermatologist.',
        'Use sunscreen daily and protect the skin from further sun.',
        'Watch the spot: rapid growth, pain, or bleeding needs an '
            'earlier visit.',
      ],
      treatment:
          'After examination, a dermatologist may treat the spot with '
          'procedures such as freezing (cryotherapy) or with '
          'prescription creams. These are prescribed only after an '
          'in-person assessment - do not self-medicate.',
    ),
    'Benign keratosis': DiseaseInfo(
      about:
          'Benign keratosis is a harmless, non-cancerous skin growth '
          'that is very common as people age. It is not contagious and '
          'does not turn into cancer.',
      causes:
          'It is linked mainly to ageing and family tendency (genetics). '
          'For some types, years of sun exposure also play a role.',
      care: [
        'Usually no treatment is needed.',
        'Leave it alone - do not try to scratch or burn it off.',
        'See a doctor if it changes quickly, bleeds, becomes painful, '
            'or starts to look very different.',
      ],
      treatment:
          'No medicine is needed. If the growth is irritated or unwanted, '
          'a dermatologist can remove it with a minor procedure such as '
          'freezing, scraping or laser treatment.',
    ),
    'Dermatofibroma': DiseaseInfo(
      about:
          'Dermatofibroma is a common, harmless firm bump within the '
          'skin, often found on the legs. It is benign and usually '
          'stays the same size for years.',
      causes:
          'The exact cause is not fully known. It sometimes appears '
          'after a minor skin injury or an insect bite.',
      care: [
        'Usually nothing needs to be done.',
        'Get it checked if it grows fast, hurts, bleeds, or changes '
            'colour.',
      ],
      treatment:
          'No medicine is required. If the bump is troublesome, a '
          'dermatologist may remove it surgically.',
    ),
    'Nevus': DiseaseInfo(
      about:
          'A nevus is a common mole - a small cluster of pigment cells '
          'in the skin. Most moles are completely harmless.',
      causes:
          'Moles are mainly due to genetics and sun exposure. Most '
          'appear during childhood and early adult life.',
      care: [
        'Check your moles regularly using the ABCDE rule: Asymmetry, '
            'irregular Border, multiple Colours, Diameter over 6 mm, '
            'Evolving (changing).',
        'Take a photo every few months to notice changes.',
        'See a dermatologist for any new, changing, itching or '
            'bleeding mole.',
        'Use sun protection to reduce new mole formation.',
      ],
      treatment:
          'A normal mole needs no treatment and no medicine. If a mole '
          'looks unusual or is changing, a doctor may remove it and '
          'examine it under a microscope (biopsy) to be safe.',
    ),
    'Vascular lesion': DiseaseInfo(
      about:
          'A vascular lesion is a harmless growth made of small blood '
          'vessels in the skin, such as a cherry angioma. These are '
          'benign and very common.',
      causes:
          'They appear mostly with ageing and family tendency. Some '
          'types can follow a minor skin injury.',
      care: [
        'Usually no action is needed.',
        'See a doctor if it bleeds repeatedly, grows quickly, or '
            'changes in appearance.',
        'Do not try to remove it at home - it can bleed a lot.',
      ],
      treatment:
          'No medicine is needed. If treatment is wanted (for example, '
          'repeated bleeding or appearance), a dermatologist can treat '
          'it with laser or a minor procedure.',
    ),
    // ---- Clinical (common skin problems) model classes ----
    'Acne': DiseaseInfo(
      about:
          'Acne is a very common skin condition where hair follicles '
          'get blocked with oil and dead skin, forming pimples, '
          'blackheads and whiteheads, mostly on the face, chest and '
          'back.',
      causes:
          'Excess oil production, blocked pores, bacteria and hormonal '
          'changes (especially in teenagers and young adults). Stress, '
          'oily cosmetics and some medicines can make it worse.',
      care: [
        'Wash the face gently twice a day; do not scrub hard.',
        'Do not squeeze or pick pimples - it causes marks and scars.',
        'Avoid heavy oily creams on the affected area.',
        'See a dermatologist if acne is severe, painful, or leaving '
            'scars or dark marks.',
      ],
      treatment:
          'Treatment depends on severity. A dermatologist may consider '
          'medicated creams or gels, and tablets for moderate to severe '
          'acne. This is decided after examination - do not start acne '
          'medicines on your own.',
    ),
    'Alopecia': DiseaseInfo(
      about:
          'Alopecia means hair loss. One common type, alopecia areata, '
          'causes round bald patches on the scalp. Other types cause '
          'general thinning of hair.',
      causes:
          'Alopecia areata is linked to the immune system attacking '
          'hair roots. Hair loss can also follow illness, stress, '
          'nutritional deficiency, thyroid problems, tight hairstyles '
          'or fungal infection of the scalp.',
      care: [
        'See a dermatologist or trichologist to find the exact type '
            'and cause.',
        'Be gentle with hair - avoid tight hairstyles and harsh '
            'chemicals.',
        'Do not start hair oils or supplements expecting regrowth '
            'without a diagnosis.',
      ],
      treatment:
          'Treatment depends on the type and cause. A doctor may '
          'consider scalp applications, injections or tablets after '
          'examination and, if needed, blood tests.',
    ),
    "Athlete's foot": DiseaseInfo(
      about:
          'Athletes foot is a fungal infection of the feet, causing '
          'itching, scaling and cracking, usually between the toes.',
      causes:
          'It is caused by fungi that grow in warm, moist places - '
          'sweaty shoes, shared bathrooms and walking barefoot in '
          'public wet areas.',
      care: [
        'Keep feet clean and dry, especially between the toes.',
        'Change socks daily and let shoes dry fully between uses.',
        'Do not share towels, socks or footwear.',
        'See a doctor if it spreads, the skin breaks, or you have '
            'diabetes.',
      ],
      treatment:
          'A doctor or pharmacist may suggest an antifungal cream; '
          'widespread or nail-involved cases may need tablets decided '
          'by a doctor. Complete the full course even if itching '
          'stops early.',
    ),
    'Candidiasis': DiseaseInfo(
      about:
          'Candidiasis is a yeast infection of the skin, common in '
          'skin folds (under the arms, groin, below the breast) and '
          'around nails. It causes red, itchy, moist patches.',
      causes:
          'It is caused by a yeast called Candida that normally lives '
          'on skin and overgrows with moisture, heat, diabetes, '
          'obesity, or after antibiotics.',
      care: [
        'Keep skin folds clean and dry.',
        'Wear loose cotton clothing.',
        'If you have diabetes, keep blood sugar controlled.',
        'See a doctor if it keeps coming back or covers a large area.',
      ],
      treatment:
          'A doctor may prescribe an antifungal cream or, for repeated '
          'cases, tablets and tests to find the reason it recurs.',
    ),
    'Cellulitis': DiseaseInfo(
      about:
          'Cellulitis is a bacterial infection of the deeper skin. '
          'The area becomes red, warm, swollen and painful, and it '
          'can spread quickly. It needs prompt medical care.',
      causes:
          'Bacteria enter through a cut, wound, insect bite, cracked '
          'skin or a fungal infection of the foot.',
      care: [
        'See a doctor the same day - do not wait with spreading '
            'redness or pain.',
        'Go to emergency care if there is fever, a red streak, or '
            'the face/eye area is involved.',
        'Keep the area clean, rest it and raise the limb if swollen.',
        'Do not massage the area or apply home remedies.',
      ],
      treatment:
          'Cellulitis is treated with antibiotic tablets or injections '
          'decided by a doctor; severe cases need hospital care. '
          'Never self-start antibiotics.',
    ),
    'Contact dermatitis': DiseaseInfo(
      about:
          'Contact dermatitis is skin inflammation caused by touching '
          'something that irritates the skin or triggers an allergy - '
          'an itchy, red, sometimes blistery rash where contact '
          'happened.',
      causes:
          'Common triggers are soaps, detergents, cosmetics, hair dye, '
          'metals like nickel (jewellery), cement, plants and some '
          'creams or perfumes.',
      care: [
        'Identify and stop using the suspected product or material.',
        'Wash the area gently with plain water.',
        'Avoid scratching; keep the skin moisturised with a plain, '
            'fragrance-free cream.',
        'See a doctor if the rash is on the face, widespread, '
            'blistered, or not improving in a week.',
      ],
      treatment:
          'A doctor may prescribe a mild steroid cream and, if needed, '
          'tests to find the exact allergy. Long-term control mainly '
          'means avoiding the trigger.',
    ),
    'Eczema': DiseaseInfo(
      about:
          'Eczema is a long-term skin condition that causes dry, '
          'itchy, red and inflamed skin. It comes and goes in flares '
          'and is very common in children and adults.',
      causes:
          'It runs in families and is linked with a weak skin barrier '
          'and an overactive immune response. Flares are triggered by '
          'dry weather, harsh soaps, dust, sweat, stress and some '
          'foods in children.',
      care: [
        'Moisturise the skin several times a day - this is the most '
            'important step.',
        'Use mild, fragrance-free cleansers; avoid hot showers.',
        'Do not scratch - it breaks the skin and invites infection.',
        'See a dermatologist for frequent flares, sleep-disturbing '
            'itch, or signs of infection (yellow crusts, pus).',
      ],
      treatment:
          'A dermatologist may consider steroid or non-steroid creams '
          'for flares, and other treatments for severe cases. Creams '
          'should be used exactly as the doctor advises.',
    ),
    'Folliculitis': DiseaseInfo(
      about:
          'Folliculitis is inflammation or infection of hair '
          'follicles, seen as small red bumps or pus-filled spots '
          'around hair roots, often on the scalp, beard area, arms '
          'or legs.',
      causes:
          'Usually bacteria entering damaged follicles; also shaving, '
          'waxing, friction, sweating, tight clothing and contaminated '
          'hot tubs.',
      care: [
        'Keep the area clean; avoid shaving over it until it heals.',
        'Do not squeeze the spots.',
        'Use warm compresses for comfort.',
        'See a doctor if it spreads, becomes painful boils, or keeps '
            'coming back.',
      ],
      treatment:
          'Mild cases settle with hygiene alone. A doctor may '
          'prescribe an antiseptic wash or antibiotic cream/tablets '
          'if it is widespread or deep.',
    ),
    'Herpes simplex': DiseaseInfo(
      about:
          'Herpes simplex causes small, painful, fluid-filled blisters '
          'in a cluster, commonly around the lips (cold sores) or '
          'genitals. The virus stays in the body and can recur.',
      causes:
          'It is caused by the herpes simplex virus, spread by close '
          'skin contact. Recurrences are triggered by fever, stress, '
          'sunlight and low immunity.',
      care: [
        'Do not touch or burst the blisters; wash hands after contact.',
        'Avoid kissing or sharing utensils/towels while sores are '
            'active.',
        'See a doctor quickly - treatment works best when started '
            'early.',
        'Seek urgent care for eye involvement or sores in a person '
            'with weak immunity.',
      ],
      treatment:
          'A doctor may prescribe antiviral tablets or cream, started '
          'as early as possible. There is no permanent cure, but '
          'treatment shortens attacks.',
    ),
    'Keloid': DiseaseInfo(
      about:
          'A keloid is a raised, thick scar that grows larger than '
          'the original wound. It is harmless but can itch, hurt or '
          'cause cosmetic concern.',
      causes:
          'It forms when the body makes too much scar tissue while '
          'healing. It follows cuts, burns, acne, piercings or '
          'surgery, and is more common in younger people and in some '
          'families.',
      care: [
        'Do not cut or burn it at home - it usually grows back '
            'bigger.',
        'Protect it from repeated injury and friction.',
        'Consult a dermatologist for treatment options.',
      ],
      treatment:
          'A dermatologist may consider steroid injections, silicone '
          'sheets, pressure therapy, laser or surgery (often combined '
          'with other treatment to prevent regrowth).',
    ),
    'Lichen planus': DiseaseInfo(
      about:
          'Lichen planus is an inflammatory skin condition causing '
          'flat, itchy, purple-coloured bumps, often on the wrists, '
          'ankles and lower back. It can also affect the mouth and '
          'nails.',
      causes:
          'It is linked to the immune system reacting against the '
          'skin. It is sometimes associated with hepatitis infection '
          'or certain medicines.',
      care: [
        'Avoid scratching and skin injury - new spots can appear '
            'where skin is scratched.',
        'Keep the skin moisturised.',
        'Tell the doctor about all medicines you take.',
        'See a dermatologist for confirmation - a skin biopsy is '
            'sometimes needed.',
      ],
      treatment:
          'A dermatologist may prescribe steroid creams or tablets and '
          'other immune-calming treatment depending on severity.',
    ),
    'Melasma / pigmentation': DiseaseInfo(
      about:
          'Melasma is a common pigmentation problem causing brown or '
          'grey-brown patches, usually on the cheeks, forehead, nose '
          'and upper lip. It is harmless but cosmetically bothersome.',
      causes:
          'Sun exposure is the main trigger, combined with hormonal '
          'changes (pregnancy, contraceptive pills) and family '
          'tendency. It is more common in women and in medium to dark '
          'skin tones.',
      care: [
        'Use sunscreen daily - without this, no treatment works well.',
        'Avoid fairness creams with unknown ingredients and home '
            'bleaching remedies - they can worsen pigmentation.',
        'Be patient: pigmentation improves slowly over months.',
      ],
      treatment:
          'A dermatologist may consider pigment-reducing creams, '
          'chemical peels or other procedures after examining the '
          'skin. Self-bought lightening creams can damage the skin.',
    ),
    'Nail fungus': DiseaseInfo(
      about:
          'Nail fungus is a fungal infection of the nails. The nail '
          'becomes thick, yellow-brown, brittle and may lift from '
          'the nail bed.',
      causes:
          'Fungi spread from athletes foot or from nail trauma, and '
          'grow in warm, moist shoes. Diabetes and low immunity '
          'increase the risk.',
      care: [
        'Keep feet and hands dry; change socks regularly.',
        'Do not share nail cutters; clean them before use.',
        'Treatment takes months because nails grow slowly - do not '
            'stop early.',
        'If you have diabetes, consult a doctor before home '
            'treatment.',
      ],
      treatment:
          'A doctor confirms the diagnosis (sometimes with a nail '
          'test) and may prescribe antifungal tablets or nail '
          'lacquer. Tablets need medical supervision.',
    ),
    'Pityriasis rosea': DiseaseInfo(
      about:
          'Pityriasis rosea is a harmless, self-limiting rash: it '
          'often starts with one larger oval patch, followed by '
          'smaller oval spots on the trunk in a christmas-tree '
          'pattern. It usually clears in 6 to 10 weeks.',
      causes:
          'The exact cause is not clear; it is thought to be linked '
          'to common viruses. It is not highly contagious.',
      care: [
        'Usually no treatment is needed - it resolves on its own.',
        'Moisturise and avoid harsh soaps if the skin is dry or '
            'itchy.',
        'See a doctor if the rash is very itchy, atypical, or does '
            'not clear in about 3 months.',
      ],
      treatment:
          'A doctor may suggest a mild cream or anti-itch medicine if '
          'needed, and can rule out other similar-looking rashes.',
    ),
    'Pityriasis versicolor': DiseaseInfo(
      about:
          'Pityriasis versicolor is a common fungal skin problem '
          'causing light or dark patches with fine scaling, mostly '
          'on the chest, back, neck and upper arms. In India it is '
          'often called pan-bahri.',
      causes:
          'It is caused by a yeast that normally lives on skin and '
          'overgrows in hot, humid weather, oily skin and sweating.',
      care: [
        'Keep the skin as dry as practical in humid weather.',
        'Colour changes can take months to even out after the '
            'fungus is treated - this is normal.',
        'It often comes back in summer; see a doctor for a '
            'maintenance plan.',
      ],
      treatment:
          'A doctor may prescribe an antifungal shampoo or cream; '
          'widespread or repeated cases may need antifungal tablets.',
    ),
    'Psoriasis': DiseaseInfo(
      about:
          'Psoriasis is a long-term immune-related skin condition '
          'causing red, well-defined patches with silvery-white '
          'scales, commonly on the elbows, knees, scalp and lower '
          'back. It is not contagious.',
      causes:
          'The immune system speeds up skin cell production. It runs '
          'in families and flares with stress, infections, cold '
          'weather, skin injury, smoking and alcohol.',
      care: [
        'Moisturise daily and do not pick or peel the scales.',
        'Note what triggers your flares and avoid smoking/alcohol.',
        'See a dermatologist - long-term control needs a plan.',
        'Tell the doctor about joint pain or stiffness - psoriasis '
            'can affect the joints.',
      ],
      treatment:
          'A dermatologist may consider medicated creams, light '
          'therapy (phototherapy), or tablets/injections for moderate '
          'to severe disease. Never use strong steroid creams '
          'long-term without medical supervision.',
    ),
    'Rosacea': DiseaseInfo(
      about:
          'Rosacea is a long-term facial condition causing redness, '
          'visible small blood vessels, flushing and sometimes '
          'acne-like bumps on the cheeks, nose and forehead.',
      causes:
          'The exact cause is unclear. Flares are triggered by '
          'sunlight, heat, spicy food, alcohol, stress and some skin '
          'products.',
      care: [
        'Use gentle, fragrance-free skin care and daily sunscreen.',
        'Identify and avoid your personal triggers.',
        'Do not use steroid creams on the face unless a doctor '
            'prescribes them - they can worsen rosacea.',
        'See an eye doctor if eyes feel gritty or red.',
      ],
      treatment:
          'A dermatologist may prescribe specific creams or tablets '
          'and may suggest laser treatment for visible vessels.',
    ),
    'Scabies': DiseaseInfo(
      about:
          'Scabies is an intensely itchy skin infestation caused by a '
          'tiny mite. Itching is worst at night. Common sites are '
          'finger webs, wrists, waist, buttocks and genitals. It '
          'spreads easily within families.',
      causes:
          'The mite spreads by close skin-to-skin contact and, less '
          'often, shared bedding or clothing.',
      care: [
        'All close contacts and family members usually need '
            'treatment at the same time, even without itching.',
        'Wash clothes and bedding in hot water and dry in sunlight '
            'on treatment day.',
        'Itching can continue 2 to 4 weeks after successful '
            'treatment - this does not always mean failure.',
        'See a doctor for babies, pregnant women, widespread sores '
            'or no improvement.',
      ],
      treatment:
          'A doctor prescribes a mite-killing cream or lotion (and '
          'sometimes tablets) with exact instructions for the whole '
          'body and all contacts. Follow the instructions fully.',
    ),
    'Seborrheic dermatitis': DiseaseInfo(
      about:
          'Seborrheic dermatitis causes flaky, greasy, yellowish '
          'scales and redness in oily areas - the scalp (dandruff), '
          'eyebrows, sides of the nose, ears and chest.',
      causes:
          'It is linked to a normal skin yeast and the skins oil '
          'production, and flares with stress, cold weather and '
          'illness.',
      care: [
        'Wash the scalp regularly; do not let heavy oil sit for '
            'days.',
        'Avoid scratching flakes off forcefully.',
        'See a doctor if it spreads widely or the skin becomes sore '
            'or infected.',
      ],
      treatment:
          'A doctor may suggest antifungal shampoo or cream and, for '
          'flares, a mild anti-inflammatory cream for short periods.',
    ),
    'Skin tags': DiseaseInfo(
      about:
          'Skin tags are small, soft, harmless skin growths that hang '
          'off the skin, common on the neck, underarms, groin and '
          'under the breast. They are very common with age.',
      causes:
          'They are linked to skin rubbing against skin, increasing '
          'age, weight gain, hormonal changes and family tendency.',
      care: [
        'No treatment is needed if they do not trouble you.',
        'Never cut, tie or burn them at home - risk of bleeding, '
            'infection and wrong diagnosis.',
        'See a doctor if a growth changes colour, bleeds, or looks '
            'different from the rest.',
      ],
      treatment:
          'A dermatologist can remove them safely in minutes with a '
          'minor procedure if they cause irritation or cosmetic '
          'concern.',
    ),
    'Squamous cell carcinoma': DiseaseInfo(
      about:
          'Squamous cell carcinoma is a type of skin cancer that '
          'grows faster than basal cell carcinoma and can spread if '
          'untreated. It may look like a scaly patch, a growing lump '
          'or a sore that does not heal.',
      causes:
          'Mainly long-term sun (UV) exposure. Risk is higher with '
          'fair skin, outdoor work, chronic wounds or scars, smoking '
          'and a weakened immune system.',
      care: [
        'See a dermatologist promptly - do not wait.',
        'Note how fast it is growing and tell the doctor.',
        'Do not try to remove or treat it at home.',
      ],
      treatment:
          'There is no self-medication. A dermatologist confirms it '
          'with a biopsy; treatment is usually surgical removal, and '
          'early treatment gives the best outcome.',
    ),
    'Tinea': DiseaseInfo(
      about:
          'Tinea (ringworm, called daad in India) is a fungal '
          'infection causing round, red, itchy patches with a '
          'clearer centre and raised edge. It can affect the body, '
          'groin, feet and scalp.',
      causes:
          'It is caused by fungi spread from other people, animals, '
          'or shared towels and clothing. Heat, humidity and '
          'sweating make it worse.',
      care: [
        'Keep the area dry; change sweaty clothes promptly.',
        'Do not share towels, clothes or razors.',
        'Never use combination steroid-antifungal creams from the '
            'chemist without a doctor - they hide the infection and '
            'make it spread (a very common problem in India).',
        'See a doctor if it is widespread, on the scalp, or keeps '
            'returning.',
      ],
      treatment:
          'A doctor prescribes a proper antifungal cream or tablets '
          'for the correct duration - stopping early is the main '
          'reason it comes back.',
    ),
    'Urticaria': DiseaseInfo(
      about:
          'Urticaria (hives) causes itchy, raised, red or skin-'
          'coloured welts that appear suddenly and fade within hours, '
          'often moving to new places. Most cases settle in days to '
          'weeks.',
      causes:
          'Common triggers are infections, foods, medicines, insect '
          'bites, heat, cold, pressure and stress. Often no single '
          'cause is found.',
      care: [
        'Note recent foods, medicines or illnesses before an '
            'attack and tell the doctor.',
        'Avoid scratching and known triggers.',
        'Seek emergency care immediately if there is swelling of '
            'lips/tongue or difficulty breathing.',
      ],
      treatment:
          'A doctor may prescribe anti-allergy (antihistamine) '
          'tablets and look for the cause if attacks keep returning '
          'beyond 6 weeks.',
    ),
    'Vitiligo': DiseaseInfo(
      about:
          'Vitiligo causes smooth, white patches where the skin '
          'loses its pigment. It is not an infection and is not '
          'contagious. It can affect any body part and is more '
          'visible on darker skin.',
      causes:
          'The pigment-making cells are lost, most likely due to an '
          'immune reaction. It can run in families and may be '
          'associated with thyroid problems.',
      care: [
        'Protect white patches with sunscreen - they sunburn '
            'easily.',
        'Avoid skin injury and harsh fairness or bleaching creams.',
        'See a dermatologist early - treatment works better on new '
            'patches.',
        'Emotional support matters; the condition is cosmetic, not '
            'dangerous.',
      ],
      treatment:
          'A dermatologist may consider medicated creams, light '
          'therapy (phototherapy) or procedures for stable patches, '
          'after examination and sometimes thyroid tests.',
    ),
    'Warts': DiseaseInfo(
      about:
          'Warts are small, rough skin growths caused by a virus. '
          'They are common on the hands, feet (plantar warts), face '
          'and other areas, especially in children and young adults.',
      causes:
          'They are caused by the human papillomavirus (HPV), which '
          'enters through tiny skin cuts. They spread by touch and '
          'from one body part to another.',
      care: [
        'Do not pick, cut or bite warts - they can spread.',
        'Do not share towels, razors or footwear.',
        'Cover plantar warts in public wet areas like pools.',
        'See a doctor for warts on the face or genitals, many '
            'warts, or warts that do not go away.',
      ],
      treatment:
          'Many warts clear on their own over time. A dermatologist '
          'may use freezing (cryotherapy), chemical treatment, or '
          'minor procedures - several sessions are often needed.',
    ),
    'Pneumonia': DiseaseInfo(
      about:
          'Pneumonia is an infection of the lungs in which the tiny air '
          'sacs (alveoli) fill with fluid or pus. On a chest X-ray it '
          'usually appears as white patches (consolidation) in one or '
          'both lungs. It can range from mild to serious and needs '
          'in-person medical care.',
      causes:
          'It is most often caused by bacteria (such as Streptococcus '
          'pneumoniae) or viruses (such as influenza or RSV). Risk is '
          'higher in young children, older adults, smokers, and people '
          'with weak immunity or long-term lung disease. The X-ray '
          'model can flag that pneumonia may be present; it cannot '
          'tell which germ caused it.',
      care: [
        'See a doctor promptly - do not wait if there is breathlessness, chest pain, or high fever.',
        'Note your symptoms (fever, cough, breathing difficulty) and tell the doctor.',
        'Carry this report and the original X-ray to the appointment.',
        'Rest and drink fluids; do not start antibiotics or other medicines on your own.',
      ],
      treatment:
          'Treatment is decided by a doctor after examination and, if '
          'needed, blood tests or other investigations. Bacterial '
          'pneumonia is usually treated with antibiotics prescribed by '
          'the doctor; severe cases may need hospital care and oxygen. '
          'This is general information only - not a prescription.',
    ),
    'Fracture': DiseaseInfo(
      about:
          'A fracture is a break or crack in a bone. On an X-ray it '
          'usually appears as a line or gap across the bone. Fractures '
          'need prompt in-person care so the bone heals in the correct '
          'position.',
      causes:
          'Fractures are usually caused by falls, road accidents, '
          'sports injuries or a direct blow. Bones weakened by '
          'conditions such as osteoporosis can break with much less '
          'force, especially in older adults.',
      care: [
        'See an orthopaedic doctor promptly - do not delay.',
        'Keep the injured part still and supported; avoid putting weight or load on it.',
        'A cold pack (with a cloth in between) can help reduce swelling in the first day.',
        'Carry this report and the original X-ray to the appointment.',
      ],
      treatment:
          'Treatment is decided by an orthopaedic doctor after '
          'examination. Depending on the type of fracture, options may '
          'include a splint or plaster cast, setting the bone back '
          'into position (reduction), or surgery with plates or '
          'screws. This is general information only - not a '
          'prescription.',
    ),
    'No fracture': DiseaseInfo(
      about:
          'The AI model did not find a fracture in this bone X-ray. '
          'This is a screening result only: very fine (hairline) '
          'fractures can be missed on a single view, and this does '
          'not replace a radiologist reading the X-ray.',
      causes:
          'Not applicable - no fracture was flagged by the model in '
          'this image. Pain or swelling can still be present due to a '
          'sprain, bruise or other injury that an X-ray does not show '
          'well.',
      care: [
        'Rest the injured part and avoid heavy use for a few days.',
        'If pain or swelling does not improve in 3-4 days, or gets worse, see a doctor - a repeat X-ray may be advised.',
        'Keep the X-ray and this report for your medical records.',
      ],
      treatment:
          'No treatment is suggested by this screening result. Any '
          'treatment decision is made by a doctor based on symptoms '
          'and examination, not on this app.',
    ),
    'Healthy': DiseaseInfo(
      about:
          'The AI model found no signs of osteoarthritis in this knee '
          'X-ray. This is a screening result only and does not '
          'replace a radiologist reading the X-ray.',
      causes:
          'Not applicable - no abnormality was flagged by the model '
          'in this image. Knee pain can also come from muscles, '
          'ligaments or the kneecap, which an X-ray does not show '
          'well.',
      care: [
        'Stay active - regular movement keeps the knee joint healthy.',
        'If you have knee pain that does not settle in a few weeks, see a doctor even with a healthy screening result.',
        'Keep the X-ray and this report for your medical records.',
      ],
      treatment:
          'No treatment is suggested by this screening result. Any '
          'treatment decision is made by a doctor based on symptoms '
          'and examination, not on this app.',
    ),
    'Mild osteoarthritis': DiseaseInfo(
      about:
          'Osteoarthritis is wear-and-tear of the knee joint: the '
          'smooth cartilage covering the bone ends slowly thins. '
          'In mild osteoarthritis the joint space is slightly '
          'narrowed and small bony spurs may be forming. It is very '
          'common with age and is not dangerous, but it can cause '
          'pain and stiffness.',
      causes:
          'It develops over years from ageing, body weight, old knee '
          'injuries, and repeated heavy use of the joint. It is more '
          'common in women and in people with a family history.',
      care: [
        'Stay active - low-impact exercise like walking, cycling and swimming helps more than full rest.',
        'Strengthen the thigh muscles (quadriceps) - they protect the knee.',
        'If overweight, even a small weight loss reduces knee load significantly.',
        'See a doctor if pain keeps troubling you or the knee swells often.',
      ],
      treatment:
          'Treatment is decided by a doctor after examination. '
          'Options may include physiotherapy and exercise plans, '
          'pain-relief medicines for short periods, supportive '
          'braces, or injections in some cases. This is general '
          'information only - not a prescription.',
    ),
    'Severe osteoarthritis': DiseaseInfo(
      about:
          'In severe osteoarthritis the cartilage of the knee joint '
          'is badly worn, the joint space is markedly reduced, and '
          'the bones may rub against each other. It commonly causes '
          'daily pain, stiffness, swelling and difficulty walking or '
          'climbing stairs.',
      causes:
          'It is the advanced stage of long-standing wear-and-tear, '
          'influenced by age, weight, previous knee injuries or '
          'surgery, and joint alignment (bow legs / knock knees).',
      care: [
        'Consult an orthopaedic doctor for a proper treatment plan.',
        'Keep moving within comfort - complete rest weakens the muscles that support the knee.',
        'Use a walking support if your doctor advises it, and avoid high-impact activity.',
        'Carry this report and the original X-ray to the appointment.',
      ],
      treatment:
          'Treatment is decided by an orthopaedic doctor after '
          'examination. Options may include physiotherapy, '
          'pain-relief medicines, or injections; in advanced cases '
          'the doctor may discuss knee replacement surgery. This is '
          'general information only - not a prescription.',
    ),
    'Normal': DiseaseInfo(
      about:
          'The AI model did not find signs of pneumonia in this chest '
          'X-ray. This is a screening result only: it does not rule '
          'out every chest or lung condition, and it does not replace '
          'a radiologist reading the X-ray.',
      causes:
          'Not applicable - no abnormality was flagged by the model '
          'in this image.',
      care: [
        'If you have no symptoms, no action is usually needed.',
        'If you have fever, cough, chest pain or breathlessness that persists, see a doctor even with a normal screening result.',
        'Keep the X-ray and this report for your medical records.',
      ],
      treatment:
          'No treatment is suggested by this screening result. Any '
          'treatment decision is made by a doctor based on symptoms '
          'and examination, not on this app.',
    ),
    'Healthy teeth': DiseaseInfo(
      about:
          'The AI model found no cavity, deep decay or impacted '
          'tooth in the main part of this dental X-ray. This is a '
          'screening result only and does not replace a dentist '
          'examining the full X-ray and your teeth.',
      causes:
          'Not applicable - no abnormality was flagged by the model '
          'in this part of the image. Small cavities between teeth '
          'can be hard to see on a screening scan.',
      care: [
        'Brush twice a day with fluoride toothpaste and clean between teeth.',
        'Keep up regular dental check-ups every 6-12 months.',
        'See a dentist if you get tooth pain, sensitivity or swelling, even with a healthy screening result.',
      ],
      treatment:
          'No treatment is suggested by this screening result. Any '
          'treatment decision is made by a dentist after '
          'examination, not on this app.',
    ),
    'Cavity (caries)': DiseaseInfo(
      about:
          'A cavity is tooth decay: bacteria in plaque produce '
          'acids that slowly dissolve the tooth surface, making a '
          'hole. On an X-ray a cavity shows as a darker area in '
          'the tooth. Early cavities may cause no pain at all, '
          'which is why X-ray screening helps catch them.',
      causes:
          'Frequent sugary food and drinks, poor brushing, and dry '
          'mouth let plaque bacteria attack the teeth over time.',
      care: [
        'See a dentist - a small cavity is usually a quick, simple filling.',
        'Brush twice daily with fluoride toothpaste; spit, do not rinse, after brushing.',
        'Cut down on sugary snacks and fizzy drinks, especially between meals.',
      ],
      treatment:
          'Treatment is decided by a dentist after examination. '
          'Options may include a filling, fluoride treatment, or '
          'other repair of the tooth. This is general information '
          'only - not a prescription.',
    ),
    'Impacted tooth': DiseaseInfo(
      about:
          'An impacted tooth is stuck under the gum or bone and '
          'cannot come out fully into its normal position. Wisdom '
          'teeth (the last molars) are the most commonly impacted. '
          'Many impacted teeth cause no trouble, but some trap '
          'food and cause repeated gum infection, pain or damage '
          'to the neighbouring tooth.',
      causes:
          'There is not enough space in the jaw, or the tooth is '
          'growing at an angle and gets blocked by the tooth in '
          'front of it.',
      care: [
        'Show the X-ray to a dentist for a review of the tooth position.',
        'Keep the area clean - food trapped near a half-out wisdom tooth causes most problems.',
        'Mention any pain, swelling, or difficulty opening your mouth fully.',
      ],
      treatment:
          'Treatment is decided by a dentist after examination. '
          'Options may include simply monitoring the tooth, or '
          'removing it if it is causing problems. This is general '
          'information only - not a prescription.',
    ),
  };

  /// Education content for a model label; a safe generic text is used
  /// for anything unexpected.
  static DiseaseInfo forLabel(String label) {
    return _byLabel[label] ??
        const DiseaseInfo(
          about:
              'This is an AI-generated screening result. Only a '
              'dermatologist can confirm what this skin change is, '
              'after physical examination.',
          causes:
              'The cause can be identified only after an in-person '
              'examination by a dermatologist.',
          care: [
            'Visit a dermatologist for a confirmed diagnosis.',
            'Avoid self-medication and home remedies.',
          ],
          treatment:
              'Treatment, if any is needed, is decided by the '
              'dermatologist after examination.',
        );
  }
}
