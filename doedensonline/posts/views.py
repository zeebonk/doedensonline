from django.views.generic import ListView

from .models import Post


class PostList(ListView):
    paginate_by = 5
    model = Post
