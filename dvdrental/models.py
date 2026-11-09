# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.db import models


class Actor(models.Model):
    actor_id = models.AutoField(primary_key=True)
    first_name = models.TextField()
    last_name = models.TextField()
    last_update = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'actor'


class Address(models.Model):
    address_id = models.AutoField(primary_key=True)
    address = models.TextField()
    address2 = models.TextField(blank=True, null=True)
    district = models.TextField()
    city = models.ForeignKey('City', models.DO_NOTHING)
    postal_code = models.TextField(blank=True, null=True)
    phone = models.TextField()
    last_update = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'address'


class Category(models.Model):
    category_id = models.AutoField(primary_key=True)
    name = models.TextField()
    last_update = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'category'


class City(models.Model):
    city_id = models.AutoField(primary_key=True)
    city = models.TextField()
    country = models.ForeignKey('Country', models.DO_NOTHING)
    last_update = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'city'


class Country(models.Model):
    country_id = models.AutoField(primary_key=True)
    country = models.TextField()
    last_update = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'country'


class Customer(models.Model):
    customer_id = models.AutoField(primary_key=True)
    store = models.ForeignKey('Store', models.DO_NOTHING)
    first_name = models.TextField()
    last_name = models.TextField()
    email = models.TextField(blank=True, null=True)
    address = models.ForeignKey(Address, models.DO_NOTHING)
    activebool = models.BooleanField()
    create_date = models.DateField()
    last_update = models.DateTimeField(blank=True, null=True)
    active = models.IntegerField(blank=True, null=True)
    uuid = models.UUIDField(unique=True)

    class Meta:
        managed = False
        db_table = 'customer'


class Film(models.Model):
    film_id = models.AutoField(primary_key=True)
    title = models.TextField()
    description = models.TextField(blank=True, null=True)
    release_year = models.IntegerField(blank=True, null=True)
    language = models.ForeignKey('Language', models.DO_NOTHING)
    original_language = models.ForeignKey('Language', models.DO_NOTHING, related_name='film_original_language_set', blank=True, null=True)
    rental_duration = models.SmallIntegerField()
    rental_rate = models.DecimalField(max_digits=4, decimal_places=2)
    length = models.SmallIntegerField(blank=True, null=True)
    replacement_cost = models.DecimalField(max_digits=5, decimal_places=2)
    rating = models.TextField(blank=True, null=True)  # This field type is a guess.
    last_update = models.DateTimeField()
    special_features = models.TextField(blank=True, null=True)  # This field type is a guess.
    fulltext = models.TextField()  # This field type is a guess.
    length_hours = models.DecimalField(max_digits=4, decimal_places=2, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'film'


class FilmActor(models.Model):
    pk = models.CompositePrimaryKey('actor_id', 'film_id')
    actor = models.ForeignKey(Actor, models.DO_NOTHING)
    film = models.ForeignKey(Film, models.DO_NOTHING)
    last_update = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'film_actor'


class FilmCategory(models.Model):
    pk = models.CompositePrimaryKey('film_id', 'category_id')
    film = models.ForeignKey(Film, models.DO_NOTHING)
    category = models.ForeignKey(Category, models.DO_NOTHING)
    last_update = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'film_category'


class FilmEmbedding(models.Model):
    film = models.OneToOneField(Film, models.DB_CASCADE, primary_key=True)
    embedding = models.TextField()  # This field type is a guess.
    last_update = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'film_embedding'


class Inventory(models.Model):
    inventory_id = models.AutoField(primary_key=True)
    film = models.ForeignKey(Film, models.DO_NOTHING)
    store = models.ForeignKey('Store', models.DO_NOTHING)
    last_update = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'inventory'


class Language(models.Model):
    language_id = models.AutoField(primary_key=True)
    name = models.TextField()
    last_update = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'language'


class Payment(models.Model):
    pk = models.CompositePrimaryKey('payment_date', 'payment_id')
    payment_id = models.IntegerField()
    customer_id = models.IntegerField()
    staff_id = models.IntegerField()
    rental_id = models.IntegerField()
    amount = models.DecimalField(max_digits=5, decimal_places=2)
    payment_date = models.DateTimeField()
    uuid = models.UUIDField()

    class Meta:
        managed = False
        db_table = 'payment'
        unique_together = (('uuid', 'payment_date'),)


class Rental(models.Model):
    rental_id = models.AutoField(primary_key=True)
    rental_date = models.DateTimeField()
    inventory = models.ForeignKey(Inventory, models.DO_NOTHING)
    customer = models.ForeignKey(Customer, models.DO_NOTHING)
    return_date = models.DateTimeField(blank=True, null=True)
    staff = models.ForeignKey('Staff', models.DO_NOTHING)
    last_update = models.DateTimeField()
    uuid = models.UUIDField(unique=True)

    class Meta:
        managed = False
        db_table = 'rental'
        unique_together = (('rental_date', 'inventory', 'customer'),)


class Staff(models.Model):
    staff_id = models.AutoField(primary_key=True)
    first_name = models.TextField()
    last_name = models.TextField()
    address = models.ForeignKey(Address, models.DO_NOTHING)
    email = models.TextField(blank=True, null=True)
    store = models.ForeignKey('Store', models.DO_NOTHING)
    active = models.BooleanField()
    username = models.TextField()
    password = models.TextField(blank=True, null=True)
    last_update = models.DateTimeField()
    picture = models.BinaryField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'staff'


class Store(models.Model):
    store_id = models.AutoField(primary_key=True)
    manager_staff_id = models.IntegerField(unique=True)
    address = models.ForeignKey(Address, models.DO_NOTHING)
    last_update = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'store'
