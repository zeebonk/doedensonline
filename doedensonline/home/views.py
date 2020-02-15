from django.views.generic import ListView

from doedensonline.mixins import BaseMixin
from posts.models import Post


class IndexView(BaseMixin, ListView):
    page_title = "Home"
    template_name = "home/index.html"
    queryset = Post.objects.filter(status=Post.Status.LIVE)[:3]
    context_object_name = "posts"
