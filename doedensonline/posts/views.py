from django.urls import reverse_lazy
from django.views.generic import CreateView, DetailView, ListView, UpdateView

from doedensonline.layout import (
    HTML,
    ButtonGroup,
    Field,
    Layout,
    PrimarySubmit,
    SecondayLink,
)
from doedensonline.mixins import BaseMixin

from .models import Comment, Post


class PostListView(BaseMixin, ListView):
    page_title = "Nieuwtjes"
    paginate_by = 10
    queryset = Post.objects.live()
    context_object_name = "posts"


class PostDetailView(BaseMixin, DetailView):
    page_title = "Nieuwtje bekijken"
    model = Post


class PostCreateView(BaseMixin, CreateView):
    page_title = "Nieuwtje toevoegen"
    model = Post
    fields = ["message"]
    success_url = reverse_lazy("posts:list")

    form_layout = Layout(
        Field("message"),
        ButtonGroup(PrimarySubmit("Toevoegen"), SecondayLink("Terug", "posts:list"),),
    )

    def form_valid(self, form):
        form.instance.author = self.request.user
        return super().form_valid(form)


class PostUpdateView(BaseMixin, UpdateView):
    page_title = "Nieuwtje aanpassen"
    model = Post
    fields = ["message"]
    success_url = reverse_lazy("posts:list")

    form_layout = Layout(
        Field("message"),
        ButtonGroup(
            PrimarySubmit("Wijzingen opslaan"), SecondayLink("Terug", "posts:list"),
        ),
    )

    def get_queryset(self, *args, **kwargs):
        return super().get_queryset().live().filter(author=self.request.user)


class PostDeleteView(BaseMixin, UpdateView):
    page_title = "Nieuwtje verwijderen"
    model = Post
    fields = []
    success_url = reverse_lazy("posts:list")

    form_layout = Layout(
        HTML(
            """
            {% load cards %}
            {% post_card post request.user size=12 tools=False %}
            <p>Weet je zeker dat je bovenstaande nieuwtje wilt verwijderen?</p>
            """
        ),
        ButtonGroup(
            PrimarySubmit("Ja, verwijder"), SecondayLink("Nee, ga terug", "posts:list"),
        ),
    )

    def get_queryset(self, *args, **kwargs):
        return super().get_queryset().live().filter(author=self.request.user)

    def form_valid(self, form):
        form.instance.status = Post.Status.DELETED
        return super().form_valid(form)


class CommentCreateView(BaseMixin, CreateView):
    page_title = "Reactie plaatsen"
    model = Comment
    fields = ["message"]

    form_layout = Layout(
        Field("message"),
        ButtonGroup(
            PrimarySubmit("Plaatsen"), SecondayLink("Terug", "posts:detail", "post_pk"),
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

    form_layout = Layout(
        HTML(
            """
            {% load cards %}
            {% comment_card comment request.user size=12 tools=False %}
            <p>Weet je zeker dat je bovenstaande reactie wilt verwijderen?</p>
        """
        ),
        ButtonGroup(
            PrimarySubmit("Ja, verwijder"),
            SecondayLink("Nee, ga gerug", "posts:detail", "comment.post.id"),
        ),
    )

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
