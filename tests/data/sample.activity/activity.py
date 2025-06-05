from gettext import gettext as _

from sugar4.activity import activity


class SampleActivity(activity.Activity):
    def __init__(self, handle):
        activity.Activity.__init__(self, handle)
        self._text = _("Text string")
