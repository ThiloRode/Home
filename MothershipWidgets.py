import time

import kivy
from kivy.lang import Builder


from kivy.uix.boxlayout import BoxLayout

Builder.load_file('MothershipWidgets.kv')

class HeizreglerWidget(BoxLayout):

    def __init__(self, **kwargs):
        super(HeizreglerWidget, self).__init__(**kwargs)
        self.device = None  # Referenz auf die Heizregler-Instanz

    def increase_temp(self):
        """Erhöht die Solltemperatur um 0,5°C."""
        if self.device:
            new_temp = (self.device.set_temp or 0) + 0.5
            self.device.set_temperature(new_temp)  # Änderung an die Heizregler-Instanz weiterleiten
            self.update_set_temp_display()

    def decrease_temp(self):
        """Verringert die Solltemperatur um 0,5°C."""
        if self.device:
            new_temp = (self.device.set_temp or 0) - 0.5
            self.device.set_temperature(new_temp)  # Änderung an die Heizregler-Instanz weiterleiten
            self.update_set_temp_display()

    def update_set_temp_display(self):
        """Aktualisiert die Anzeige der Solltemperatur in der GUI."""
        if self.device:
            self.ids.set_temp.text = f"{self.device.set_temp:.1f}°C"
