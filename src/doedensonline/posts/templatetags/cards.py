from django import template


register = template.Library()


@register.inclusion_tag("posts/card.html")
def post_card(item, user, details_link=False, tools=True):
    user_is_author = item.author == user
    return {
        "item": item,
        "show_tools": tools and (details_link or user_is_author),
        "detail_view": "posts:detail" if tools and details_link else None,
        "update_view": "posts:update" if tools and user_is_author else None,
        "delete_view": "posts:delete" if tools and user_is_author else None,
        "delete_title": "Nieuwtje verwijderen",
        "delete_message": "U staat op het punt uw nieuwtje, en de daar onder geplaatste reacties, te verwijderen. Weet u het zeker?",
        "header": "h3",
        "shadow": "shadow",
        "col": "col m-5 p-5",
    }


@register.inclusion_tag("posts/card.html")
def comment_card(item, user, tools=True):
    user_is_author = item.author == user
    return {
        "item": item,
        "show_tools": tools and user_is_author,
        "detail_view": None,
        "update_view": "posts:update_comment" if tools and user_is_author else None,
        "delete_view": "posts:delete_comment" if tools and user_is_author else None,
        "delete_title": "Reactie verwijderen",
        "delete_message": "U staat op het punt uw reactie te verwijderen. Weet u het zeker?",
        "header": "h5",
        "shadow": "shadow-sm",
        "col": "col-sm-8 m-4 p-5",
    }
