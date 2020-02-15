from django.contrib.auth.models import User
from django.db import models


class Post(models.Model):
    class Meta:
        ordering = ["-created_at"]

    class Status(models.TextChoices):
        LIVE = ("live", "Live")
        DELETED = ("deleted", "Deleted")

    status = models.CharField(
        max_length=10, choices=Status.choices, default=Status.LIVE
    )
    author = models.ForeignKey(User, on_delete=models.CASCADE)
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    last_modified_at = models.DateTimeField(auto_now=True)


class Comment(models.Model):
    class Meta:
        ordering = ["-created_at"]

    post = models.ForeignKey(Post, on_delete=models.CASCADE)
    author = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="post_comments"
    )
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    last_modified_at = models.DateTimeField(auto_now=True)
