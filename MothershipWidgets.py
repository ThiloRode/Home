import time

import kivy
from kivy.lang import Builder


from kivy.uix.boxlayout import BoxLayout

#Builder.load_file('MothershipWidgets.kv')

class Heizregler(BoxLayout):

    def __init__(self, **kwargs):
        super(Heizregler, self).__init__(**kwargs)
 