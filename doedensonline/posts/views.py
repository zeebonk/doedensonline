from crispy_forms.layout import HTML, Div, Field, Layout, Submit
from django.urls import reverse_lazy
from django.views.generic import CreateView, DetailView, ListView, UpdateView

from doedensonline.mixins import BaseMixin

from .models import Post


class PostListView(BaseMixin, ListView):
    page_title = "Laaste nieuwtjes"
    paginate_by = 5
    queryset = Post.objects.filter(status=Post.Status.LIVE)
    ordering = ["-created_at"]


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
        Div(
            Submit("submit", "Toevoegen", css_class="btn btn-primary"),
            HTML(
                """<a href="{% url 'posts:list' %}" class="btn btn-secondary">Terug</a>"""
            ),
            css_class="btn-group",
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

    form_layout = Layout(
        Field("message"),
        Div(
            Submit("submit", "Wijzingen opslaan", css_class="btn btn-primary"),
            HTML(
                """<a href="{% url 'posts:list' %}" class="btn btn-secondary">Terug</a>"""
            ),
            css_class="btn-group",
        ),
    )


class PostDeleteView(BaseMixin, UpdateView):
    page_title = "Nieuwtje verwijderen"
    model = Post
    fields = []
    success_url = reverse_lazy("posts:list")

    form_layout = Layout(
        HTML("<p>Weet je zeker dat je dit nieuwtje wilt verwijderen?</p>"),
        Div(
            Submit("submit", "Ja, verwijder", css_class="btn btn-primary"),
            HTML(
                """<a href="{% url 'posts:list' %}" class="btn btn-secondary">Nee, ga terug</a>"""
            ),
            css_class="btn-group",
        ),
    )

    def form_valid(self, form):
        form.instance.status = Post.Status.DELETED
        return super().form_valid(form)
