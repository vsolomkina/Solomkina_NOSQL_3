import os
import pandas as pd

# Створюємо папку import, якщо її немає
os.makedirs('import', exist_ok=True)

print("Початок конвертації файлів...")

# 1. Конвертація movies.dat
# Формат: MovieID::Title::Genres
movies = pd.read_csv('movies.dat', sep='::', engine='python', encoding='Latin-1', names=['movieId', 'title', 'genres'])
movies.to_csv('import/movies.csv', index=False)
print("✓ movies.csv створено")

# 2. Конвертація users.dat
# Формат: UserID::Gender::Age::Occupation::Zip-code
users = pd.read_csv('users.dat', sep='::', engine='python', encoding='Latin-1', names=['userId', 'gender', 'age', 'occupation', 'zipCode'])
users.to_csv('import/users.csv', index=False)
print("✓ users.csv створено")

# 3. Конвертація ratings.dat
# Формат: UserID::MovieID::Rating::Timestamp
ratings = pd.read_csv('ratings.dat', sep='::', engine='python', encoding='Latin-1', names=['userId', 'movieId', 'rating', 'timestamp'])
ratings.to_csv('import/ratings.csv', index=False)
print("✓ ratings.csv створено")

print("Усі файли успішно конвертовано та збережено в папку ./import/")