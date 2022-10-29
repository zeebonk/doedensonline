from django.urls import path

from . import views


app_name = "home"
urlpatterns = [
    path("", views.IndexView.as_view(), name="index"),
    path("accounts/login/", views.LoginView.as_view(), name="login"),
    path("accounts/logout/", views.LogoutView.as_view(), name="logout"),
]
