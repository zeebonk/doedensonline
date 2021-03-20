# fmt: off
# isort:skip_file
# flake8: noqa


# New Relic needs to be initialized before anything else
import newrelic.agent
from pathlib import Path
newrelic.agent.initialize(Path(__file__).resolve().parent / "newrelic.ini")


# Now we can continue normally
import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "doedensonline.core.settings")

application = get_wsgi_application()
application = newrelic.agent.WSGIApplicationWrapper(application)
