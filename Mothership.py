
from kivy.app import App
from kivy.lang import Builder
from kivy.uix.boxlayout import BoxLayout
from kivy.config import Config
from MothershipWidgets import Heizregler

# Load the KV files
#Builder.load_file('Mothership.kv')
Builder.load_file('MothershipWidgets.kv')  # Load the Heizregler definition

class Mothership(BoxLayout):
    def __init__(self, **kwargs):
        super(Mothership, self).__init__(**kwargs)

        # Access heiz_tab using self.ids
        for i in range(3):
            regler = Heizregler()
            self.ids.heiz_tab.add_widget(regler)

class MothershipApp(App):
    Config.set("graphics", "show_cursor", 1)
    Config.set("graphics", "allow_screensaver", 1)
    Config.write()

    def build(self):
        return Mothership()

if __name__ == '__main__':
    MothershipApp().run()
