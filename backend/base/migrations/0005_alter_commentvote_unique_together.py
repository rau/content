# Generated by Django 3.2 on 2022-07-08 20:27

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0004_auto_20220708_1944'),
    ]

    operations = [
        migrations.AlterUniqueTogether(
            name='commentvote',
            unique_together={('user', 'comment')},
        ),
    ]
