from django.urls import path

from . import views


app_name = "posts"
urlpatterns = [
    path("", views.PostListView.as_view(), name="list"),
    path("create", views.PostCreateView.as_view(), name="create"),
    path("<int:pk>/", views.PostDetailView.as_view(), name="detail"),
    path("<int:pk>/edit", views.PostUpdateView.as_view(), name="update"),
    path("<int:pk>/delete", views.PostDeleteView.as_view(), name="delete"),
    path(
        "<int:post_pk>/add_comment",
        views.CommentCreateView.as_view(),
        name="add_comment",
    ),
    path(
        "comments/<int:pk>/",
        views.CommentUpdateView.as_view(),
        name="update_comment",
    ),
    path(
        "comments/<int:pk>/delete",
        views.CommentDeleteView.as_view(),
        name="delete_comment",
    ),
]
