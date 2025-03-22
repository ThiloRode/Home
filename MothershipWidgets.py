import time

import kivy
from kivy.lang import Builder


from kivy.uix.boxlayout import BoxLayout

Builder.load_file('MothershipWidgets.kv')

class HeizreglerWidget(BoxLayout):

    def __init__(self, **kwargs):
        super(HeizreglerWidget, self).__init__(**kwargs)
 