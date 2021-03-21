from crispy_forms.layout import HTML, Div, Field, Layout  # noqa: F401, forward imports


def PrimarySubmit(text):
    return HTML(
        f"""<input type="submit" value="{ text }" name="submit" class="btn btn-primary" />"""
    )


def SecondayLink(text, route, *args):
    return HTML(
        f"""<a href="{{% url '{ route }' { " ".join(args) } %}}" class="btn btn-secondary">{ text }</a>"""
    )


def ButtonGroup(*buttons):
    return Div(*buttons, css_class="btn-group")
