from django.shortcuts import render

from posts.models import Post


def index(request):
    posts = Post.objects.order_by("-created_at")[:3]
    return render(request, "home/index.html", {"posts": posts})
