from django import template


register = template.Library()


@register.inclusion_tag("posts/card.html")
def post_card(item, user, details_link=False, flip=False, size=None, tools=True):
    user_is_author = item.author == user
    return {
        "item": item,
        "show_tools": tools and (details_link or user_is_author),
        "detail_view": "posts:detail" if tools and details_link else None,
        "update_view": "posts:update" if tools and user_is_author else None,
        "delete_view": "posts:delete" if tools and user_is_author else None,
        "flip": flip,
        "highlight": True,
        "size": size,
    }


@register.inclusion_tag("posts/card.html")
def comment_card(item, user, flip=False, size=None, tools=True):
    user_is_author = item.author == user
    return {
        "item": item,
        "show_tools": tools and user_is_author,
        "detail_view": None,
        "update_view": "posts:update_comment" if tools and user_is_author else None,
        "delete_view": "posts:delete_comment" if tools and user_is_author else None,
        "flip": flip,
        "highlight": False,
        "size": size,
    }
