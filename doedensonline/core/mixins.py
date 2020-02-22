from crispy_forms.helper import FormHelper
from django.contrib.auth.mixins import AccessMixin


class BaseMixin(AccessMixin):
    form_layout = None
    login_required = True

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["page_title"] = self.page_title
        return context

    def dispatch(self, request, *args, **kwargs):
        # Same as the LoginRequiredMixin but with the optional opt-out. Orignal
        # copied from https://github.com/django/django/blob/a6b3938afc0204093b5356ade2be30b461a698c5/django/contrib/auth/mixins.py#L47b
        if self.login_required and not request.user.is_authenticated:
            return self.handle_no_permission()
        return super().dispatch(request, *args, **kwargs)

    def get_form(self, form_class=None):
        form = super().get_form(form_class)
        if self.form_layout is not None:
            form.helper = FormHelper()
            form.helper.attrs = {"novalidate": "novalidate"}
            form.helper.layout = self.form_layout
        return form
