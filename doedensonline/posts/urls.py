from django.urls import path

from . import views


app_name = "posts"
urlpatterns = [
    path("", views.PostListView.as_view(), name="list"),
    path("create", views.PostCreateView.as_view(), name="create"),
    path("<int:pk>/", views.PostDetailView.as_view(), name="detail"),
    path("<int:pk>/delete", views.PostDeleteView.as_view(), name="delete"),
]
