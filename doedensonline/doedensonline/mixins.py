from crispy_forms.helper import FormHelper


class BaseMixin:
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["page_title"] = self.page_title
        return context

    def get_form(self, form_class=None):
        form = super().get_form(form_class)
        if hasattr(self, "form_layout"):
            form.helper = FormHelper()
            form.helper.attrs = {"novalidate": "novalidate"}
            form.helper.layout = self.form_layout
        return form
