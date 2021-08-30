from django.conf import settings
from django.db import models
from stdimage import StdImageField

from doedensonline.core.models import BaseModel


class PostQuerySet(models.QuerySet):
    def live(self):
        return self.filter(status=self.model.Status.LIVE)


class Post(BaseModel):
    class Status(models.TextChoices):
        DRAFT = ("draft", "Draft")
        LIVE = ("live", "Live")
        DELETED = ("deleted", "Deleted")

    status = models.CharField(
        max_length=10, choices=Status.choices, default=Status.DRAFT
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="posts"
    )
    message = models.TextField()
    objects = models.Manager.from_queryset(PostQuerySet)()


class CommentQuerySet(models.QuerySet):
    def live(self):
        return self.filter(status=self.model.Status.LIVE)


class Comment(BaseModel):
    class Status(models.TextChoices):
        LIVE = ("live", "Live")
        DELETED = ("deleted", "Deleted")

    status = models.CharField(
        max_length=10, choices=Status.choices, default=Status.LIVE
    )
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name="comments")
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="post_comments"
    )
    message = models.TextField()

    objects = models.Manager.from_queryset(CommentQuerySet)()


class Image(BaseModel):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name="images")
    image = StdImageField(
        upload_to='images/posts/',
        delete_orphans=True,
        variations={
            'large': (1920, 1080),
            'thumbnail': (200, 200),
        }
    )
