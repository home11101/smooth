import { CSSTransition } from 'react-transition-group';
import React from 'react';
import './fade-transition.css';

export default function FadeTransition({ in: inProp, children, timeout = 300 }: { in: boolean, children: React.ReactNode, timeout?: number }) {
  return (
    <CSSTransition in={inProp} timeout={timeout} classNames="fade" unmountOnExit>
      {children}
    </CSSTransition>
  );
} 