from django.contrib.auth import logout
from django.contrib.auth.views import LoginView
from django.forms import Form
from django.urls import reverse_lazy
from django.views.generic import FormView, ListView

from doedensonline.layout import ButtonGroup, Field, Layout, PrimarySubmit, SecondayLink
from doedensonline.mixins import BaseMixin
from posts.models import Post


class IndexView(BaseMixin, ListView):
    page_title = "Home"
    template_name = "home/index.html"
    model = Post
    context_object_name = "posts"

    def get_queryset(self, *args, **kwargs):
        return (super().get_queryset(*args, **kwargs).live())[:3]


class LoginView(BaseMixin, LoginView):
    page_title = "Login"
    login_required = False

    form_layout = Layout(
        Field("username"), Field("password"), ButtonGroup(PrimarySubmit("Inloggen")),
    )


class LogoutView(BaseMixin, FormView):
    page_title = "Uitloggen"
    template_name = "registration/logout.html"
    form_class = Form
    success_url = reverse_lazy("home:index")

    form_layout = Layout(
        ButtonGroup(PrimarySubmit("Ja"), SecondayLink("Nee", "home:index")),
    )

    def post(self, request, *args, **kwargs):
        logout(request)
        return super().post(request, *args, **kwargs)
