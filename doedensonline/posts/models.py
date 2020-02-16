from django.conf import settings
from django.db import models

from doedensonline.models import BaseModel


class Post(BaseModel):
    class Status(models.TextChoices):
        LIVE = ("live", "Live")
        DELETED = ("deleted", "Deleted")

    status = models.CharField(
        max_length=10, choices=Status.choices, default=Status.LIVE
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="posts"
    )
    message = models.TextField()


class Comment(BaseModel):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name="comments")
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="post_comments"
    )
    message = models.TextField()
