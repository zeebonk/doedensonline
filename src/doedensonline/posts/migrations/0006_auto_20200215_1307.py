# Generated by Django 3.0.3 on 2020-02-15 13:07

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("posts", "0005_post_status"),
    ]

    operations = [
        migrations.AlterField(
            model_name="post",
            name="status",
            field=models.CharField(
                choices=[("live", "Live"), ("deleted", "Deleted")],
                default="live",
                max_length=10,
            ),
        ),
    ]