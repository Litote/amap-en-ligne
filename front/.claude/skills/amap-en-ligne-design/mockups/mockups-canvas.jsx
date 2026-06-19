function MockupsCanvas() {
  return (
    <DesignCanvas>
      <DCSection
        id="member-delivery-plan"
        title="Member · Planning des livraisons"
        subtitle="documentation/feature/fr/ui/member/screen-member-02-delivery-plan.md"
      >
        <DCArtboard id="m-desktop" label="Web desktop · 1280" width={1280} height={1180}>
          <MemberDeliveryPlan breakpoint="desktop"/>
        </DCArtboard>
        <DCArtboard id="m-tablet" label="Web responsive · 800" width={800} height={1400}>
          <MemberDeliveryPlan breakpoint="tablet"/>
        </DCArtboard>
        <DCArtboard id="m-mobile" label="Mobile · 390" width={390} height={1700}>
          <MemberDeliveryPlan breakpoint="mobile"/>
        </DCArtboard>
      </DCSection>

      <DCSection
        id="coordinator-time-slots"
        title="Coordinator · Gestion des livraisons"
        subtitle="documentation/feature/fr/ui/coordinator/screen-coordinator-02-time-slots.md"
      >
        <DCArtboard id="c-desktop" label="Web desktop · 1280" width={1280} height={1350}>
          <CoordinatorTimeSlots breakpoint="desktop"/>
        </DCArtboard>
        <DCArtboard id="c-tablet" label="Web responsive · 800" width={800} height={1750}>
          <CoordinatorTimeSlots breakpoint="tablet"/>
        </DCArtboard>
        <DCArtboard id="c-mobile" label="Mobile · 390" width={390} height={2050}>
          <CoordinatorTimeSlots breakpoint="mobile"/>
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

window.MockupsCanvas = MockupsCanvas;
