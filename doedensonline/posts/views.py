from django.urls import reverse_lazy
from django.views.generic import CreateView, ListView

from .models import Post


class PostList(ListView):
    paginate_by = 5
    model = Post
    ordering = ["-created_at"]


class PostCreate(CreateView):
    model = Post
    fields = ["message"]
    success_url = reverse_lazy("posts:list")

    def form_valid(self, form):
        form.instance.author = self.request.user
        return super().form_valid(form)
