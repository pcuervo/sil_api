# Shoulda activemodel cheatsheet

# DB
should have_db_column(:title).of_type(:string).with_options(default: 'Untitled', null: false)
should have_db_index(:email).unique(:true)

# Associations
should belong_to :company
should have_one(:profile).dependent(:destroy)
should have_many(:posts).dependent(:nullify)
should have_and_belong_to_many :tags

# Validations
should     allow_value("ptico@ptico.net").for(:email)
should_not allow_value("adlkj").for(:email)

should ensure_inclusion_of(:age).in_range(18..90)

should validate_numericality_of(:age)

should ensure_length_of(:title).is_at_least(3).is_at_most(40)
should ensure_length_of(:state).is_equal_to(3)

should validate_presence_of(:title)
should validate_acceptance_of(:agreement)
should validate_uniqueness_of(:email)
should_not allow_mass_assignment_of(:password)