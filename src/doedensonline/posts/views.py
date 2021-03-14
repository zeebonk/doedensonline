from django.urls import reverse_lazy
from django.views.generic import CreateView, DetailView, ListView, UpdateView

from doedensonline.core.layout import (
    ButtonGroup,
    Field,
    Layout,
    PrimarySubmit,
    SecondayLink,
)
from doedensonline.core.mixins import BaseMixin
from doedensonline.posts.models import Comment, Post


class PostListView(BaseMixin, ListView):
    page_title = "Nieuwtjes"
    paginate_by = 10
    model = Post
    context_object_name = "posts"

    def get_queryset(self, *args, **kwargs):
        return super().get_queryset(*args, **kwargs).live()


class PostDetailView(BaseMixin, DetailView):
    page_title = "Nieuwtje bekijken"
    model = Post


class PostCreateView(BaseMixin, CreateView):
    page_title = "Nieuwtje toevoegen"
    model = Post
    fields = ["message"]
    success_url = reverse_lazy("posts:list")
    success_message = "Uw nieuwtje is successvol geplaatst."

    form_layout = Layout(
        Field("message"),
        ButtonGroup(
            PrimarySubmit("Toevoegen"),
            SecondayLink("Terug", "posts:list"),
        ),
    )

    def form_valid(self, form):
        form.instance.author = self.request.user
        return super().form_valid(form)


class PostUpdateView(BaseMixin, UpdateView):
    page_title = "Nieuwtje aanpassen"
    model = Post
    fields = ["message"]
    success_url = reverse_lazy("posts:list")
    success_message = "Uw nieuwtje is succesvol aangepast."

    form_layout = Layout(
        Field("message"),
        ButtonGroup(
            PrimarySubmit("Wijzingen opslaan"),
            SecondayLink("Terug", "posts:list"),
        ),
    )

    def get_queryset(self, *args, **kwargs):
        return (
            super()
            .get_queryset(*args, **kwargs)
            .live()
            .filter(author=self.request.user)
        )


class PostDeleteView(BaseMixin, UpdateView):
    page_title = "Nieuwtje verwijderen"
    model = Post
    fields = []
    success_url = reverse_lazy("posts:list")
    success_message = "Uw nieuwtje is succesvol verwijderd."

    def get_queryset(self, *args, **kwargs):
        return (
            super()
            .get_queryset(*args, **kwargs)
            .live()
            .filter(author=self.request.user)
        )

    def form_valid(self, form):
        form.instance.status = Post.Status.DELETED
        return super().form_valid(form)


class CommentCreateView(BaseMixin, CreateView):
    page_title = "Reactie plaatsen"
    model = Comment
    fields = ["message"]
    success_message = "Uw reactie is successvol geplaatst."

    form_layout = Layout(
        Field("message"),
        ButtonGroup(
            PrimarySubmit("Plaatsen"),
            SecondayLink("Terug", "posts:detail", "post_pk"),
        ),
    )

    def get_success_url(self):
        return reverse_lazy("posts:detail", kwargs={"pk": self.kwargs["post_pk"]})

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["post_pk"] = self.kwargs["post_pk"]
        return context

    def form_valid(self, form):
        form.instance.author = self.request.user
        form.instance.post = Post.objects.get(id=self.kwargs["post_pk"])
        return super().form_valid(form)


class CommentUpdateView(BaseMixin, UpdateView):
    page_title = "Reactie aanpassen"
    model = Comment
    fields = ["message"]
    success_message = "Uw reactie is successvol aangepast."

    form_layout = Layout(
        Field("message"),
        ButtonGroup(
            PrimarySubmit("Wijzingen opslaan"),
            SecondayLink("Terug", "posts:detail", "comment.post.id"),
        ),
    )

    def get_queryset(self, *args, **kwargs):
        return (
            super()
            .get_queryset(*args, **kwargs)
            .live()
            .filter(author=self.request.user)
        )

    def get_success_url(self):
        return reverse_lazy("posts:detail", kwargs={"pk": self.object.post.id})


class CommentDeleteView(BaseMixin, UpdateView):
    page_title = "Reactie verwijderen"
    model = Comment
    fields = []
    success_message = "Uw reactie is successvol verwijderd."

    def get_queryset(self, *args, **kwargs):
        return (
            super()
            .get_queryset(*args, **kwargs)
            .live()
            .filter(author=self.request.user)
        )

    def form_valid(self, form):
        form.instance.status = Comment.Status.DELETED
        return super().form_valid(form)

    def get_success_url(self):
        return reverse_lazy("posts:detail", kwargs={"pk": self.object.post.id})
