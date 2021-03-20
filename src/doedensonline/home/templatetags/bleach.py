import bleach
from django import template
from django.utils.safestring import mark_safe


register = template.Library()


@register.filter(name="bleach")
def bleach_value(value):
    if value is None:
        return None

    tags = [
        "a",
        "p",
        "strong",
        "em",
        "u",
        "s",
        "ol",
        "ul",
        "li",
        "sub",
        "sup",
        "br",
    ]

    value = str(value)
    value = bleach.clean(value, tags=tags)

    return mark_safe(value)
