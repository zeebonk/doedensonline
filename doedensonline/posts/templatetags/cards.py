from django import template


register = template.Library()


@register.inclusion_tag("posts/card.html")
def post_card(item, user, size, details_link=False, flip=False):
    user_is_author = item.author == user
    return {
        "item": item,
        "size": size,
        "show_tools": details_link or user_is_author,
        "detail_view": "posts:detail" if details_link else None,
        "update_view": "posts:update" if user_is_author else None,
        "delete_view": "posts:delete" if user_is_author else None,
        "flip": flip,
        "highlight": True,
    }


@register.inclusion_tag("posts/card.html")
def comment_card(item, user, size, flip=False):
    user_is_author = item.author == user
    return {
        "item": item,
        "size": size,
        "show_tools": user_is_author,
        "detail_view": None,
        "update_view": "posts:update_comment" if user_is_author else None,
        "delete_view": "posts:delete_comment" if user_is_author else None,
        "flip": flip,
        "highlight": False,
    }
